# frozen_string_literal: true

# Copyright 2019 Matthew B. Gray
# Copyright 2019 Steven C Hartley
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Token::LookupOrCreateUser is used to create new User records based on JWT tokens
# It also whitelists paths for redirct from the token
# This is useful because a User may end up on a Reservation form for a Membership
# Users are allowed to see a lot before they're asked to acutally give us their details
class Token::LookupOrCreateUser
  include Rails.application.routes.url_helpers

  attr_reader :token, :secret

  # PATH_LIST contains matches for paths we will allow for client redirect
  # If it's not in this list, then you're going to a default location
  PATH_LIST = [
    "/reservations/new?",
    "/reservations"
  ].freeze

  def initialize(token:, secret:)
    @token = token
    @secret = secret
  end

  def call
    check_token
    check_secret

    decode_token
    return false if errors.any?

    lookup_and_validate_user
    return false if errors.any?

    @user
  end

  def path
    given_path = @token.first["path"]

    PATH_LIST.each do |legal_path|
      return given_path if given_path.start_with?(legal_path)
    end

    nil
  end

  def errors
    @errors ||= []
  end

  private

  def check_token
    errors << "missing token" unless token.present?
  end

  def check_secret
    errors << "cannot decode without secret" unless secret.present?
  end

  def decode_token
    @token = JWT.decode(token, secret, "HS256")
  rescue JWT::ExpiredSignature
    errors << "token has expired"
  rescue JWT::DecodeError
    errors << "token is malformed"
  end

  def lookup_and_validate_user
    lookup_email = @token.first["email"]&.downcase
    @user = User.find_or_create_by(email: lookup_email)
    unless @user.valid?
      @user.errors.full_messages.each do |validation_error|
        errors << validation_error
      end
    end
  end
end
