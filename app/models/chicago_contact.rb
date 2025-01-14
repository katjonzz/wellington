# frozen_string_literal: true
# Copyright 2019 Matthew B. Gray
# # Copyright 2020 Victoria Garcia
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

# ChicagoContact represents a user's details as they enter them in their membership form
# User is associated to ChicagoContact through the Claim join table
# Membership is associated to ChicagoContact through the Reservation on Claim
# This very tightly coupled to app/views/reservations/_chicago_contact_form.html.erb
# ChicagoContact is created when a user creates a Reservation against a Membership

require 'time'
require_relative '../validators/email_for_pubs_validator'

class ChicagoContact < ApplicationRecord

  include Benefitable
  # TODO Move this to i18n
  PAPERPUBS_ELECTRONIC = "send_me_email"
  PAPERPUBS_MAIL = "send_me_post"
  PAPERPUBS_BOTH = "send_me_email_and_post"
  PAPERPUBS_NONE = "no_paper_pubs"

  PAPERPUBS_OPTIONS = [
    PAPERPUBS_ELECTRONIC,
    PAPERPUBS_MAIL,
    PAPERPUBS_BOTH,
    PAPERPUBS_NONE
  ].freeze

  PERMITTED_PARAMS = [
    :title,
    :first_name,
    :last_name,
    :preferred_first_name,
    :preferred_last_name,
    :badge_title,
    :badge_subtitle,
    :share_with_future_worldcons,
    :show_in_listings,
    :address_line_1,
    :address_line_2,
    :city,
    :province,
    :postal,
    :country,
    :publication_format,
    :interest_volunteering,
    :interest_accessibility_services,
    :interest_being_on_program,
    :interest_dealers,
    :interest_selling_at_art_show,
    :interest_exhibiting,
    :interest_performing,
    :mail_souvenir_book,
    :installment_wanted,
    :date_of_birth,
    :email
  ].freeze

  belongs_to :claim, required: false
  has_many :cart_items, :as => :benefitable

  attr_reader :for_import
  attr_accessor :dob_array

  validates :first_name, presence: true, unless: :for_import
  validates :last_name, presence: true, unless: :for_import

  validates :address_line_1, presence: true, unless: :for_import
  validates :country, presence: true, unless: :for_import
  validates :publication_format, inclusion: { in: PAPERPUBS_OPTIONS }
  validates_with EmailForPubsValidator, fields: [:email, :publication_format]

  def as_import
    @for_import = true
    self
  end

  def for_user(user)
    write_attribute(:email, user.email) if user.present?
    self
  end

  # This maps loosely to what we promise on the form, we use preferred name but fall back to legal name
  def to_s
    if preferred_first_name.present? || preferred_last_name.present?
      "#{preferred_first_name} #{preferred_last_name}"
    else
      "#{title} #{first_name} #{last_name}"
    end.strip
  end

  def hugo_name
    "#{first_name} #{last_name}".strip
  end

  def legal_name
    "#{title} #{first_name} #{last_name}".strip
  end

  def preferred_name
    "#{title} #{first_name} #{last_name}".strip
  end

  def playful_nickname
    if fun_badge_title?
      "#{nickname} (psst, we know it's really you #{badge_title.humanize})"
    else
      nickname
    end
  end

  def shortened_display_name
    name_options = [hugo_name, "#{preferred_first_name} #{preferred_last_name}"]
    maybe_truncation = ""

    case
    when preferred_first_name.present? ^ preferred_last_name.present?
      maybe_truncation = preferred_first_name || preferred_last_name
    when preferred_first_name.present? && preferred_last_name.present?
      maybe_truncation = "#{preferred_first_name[0, 1]}. #{preferred_last_name}"
    when first_name.present? ^ last_name.present?
      # This isn't actually supposed to happen, ActiveRecord-wise, but I know
      # there are fen with mononyms out there, so...
      maybe_truncation = first_name || last_name
    when first_name.present? && last_name.present?
      # first_name and last_name are required by the model, so this is actually
      # a constructive default.
      maybe_truncation = "#{first_name[0, 1]}. #{last_name}"
    end

    name_options.push(maybe_truncation)
    truncatedest = name_options.filter {|n| n.strip.length > 0}.max_by {|n| -n.strip.length}
    truncatedest.strip
  end

  def name_for_cart
    self.to_s
  end

  def nickname
    preferred_first_name || first_name || ""
  end

  def fun_badge_title?
    return false if !badge_title.present?  # if you've set one
    return false if badge_title.match(/\s/)      # breif, so doesn't have whitespace
    return false if to_s.downcase.include?(badge_title.downcase) # isn't part of your preferred name
    true
  end
end
