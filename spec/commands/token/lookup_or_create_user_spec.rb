# frozen_string_literal: true

# Copyright 2019 Matthew B. Gray
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

require "rails_helper"

RSpec.describe Token::LookupOrCreateUser do
  let(:good_secret) { "you'll never find the treasure" }
  let(:good_email) { "willy_wönka@chocolate_factory.nz" }
  let(:user) { create(:user) }
  let(:encoded_token) { JWT.encode(login_info, good_secret, "HS256") }

  subject(:command) { Token::LookupOrCreateUser.new(token: encoded_token, secret: good_secret) }

  context "with missing token" do
    let(:encoded_token) { "" }

    it "sets error" do
      expect(command.call).to be_falsey
      expect(command.errors).to include(/missing/i)
    end
  end

  context "with malformed token" do
    let(:encoded_token) { "hax0r" }

    it "sets error" do
      expect(command.call).to be_falsey
      expect(command.errors).to include(/malformed/i)
    end
  end

  context "with expired token" do
    let(:login_info) do
      {
        exp: 1.second.ago.to_i,
        email: user.email,
      }
    end

    it "sets error" do
      expect(command.call).to be_falsey
      expect(command.errors).to include(/expired/i)
    end
  end

  context "with invalid email address" do
    let(:login_info) do
      {
        exp: 10.seconds.from_now.to_i,
        email: "never gonna give you up",
      }
    end

    it "sets error" do
      expect(command.call).to be_falsey
      expect(command.errors).to include(/email/i)
    end

    it "doesn't create new users" do
      expect { command.call }.to_not change { User.count }
    end
  end

  context "with new user" do
    let(:new_email) { "aaa@aaa.aaa" }
    let(:login_info) do
      {
        exp: 10.seconds.from_now.to_i,
        email: new_email,
      }
    end

    it "succeeds" do
      expect(command.call).to be_truthy
    end

    it "creates a new user" do
      expect { command.call }.to change { User.count }.by(1)
      expect(User.last.email).to eq(new_email)
    end
  end

  context "with credentials of legit user" do
    let(:login_info) do
      {
        exp: 10.seconds.from_now.to_i,
        email: user.email,
      }
    end

    it "returns user from the database" do
      expect(command.call).to eq(user)
    end
  end
end