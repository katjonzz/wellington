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

require "csv"

class Import::DublinMembers
  HEADINGS = [
    "eligibility",
    "DUB#",
    "NZ#",
    "Class Type",
    "FNAME",
    "LNAME",
    "combined",
    "EMAIL",
    "CITY",
    "STATE",
    "COUNTRY",
    "notes"
  ]

  attr_reader :errors, :csv

  def initialize(io_reader, description)
    @csv = CSV.parse(io_reader)
    @errors = []
  end

  def call
    if !headings.present?
      return true
    end

    if headings != HEADINGS
      errors << "Headings don't match. Got #{headings}, want #{HEADINGS}"
      return false
    end

    rows.each.with_index do |cells, n|
      row = Hash[HEADINGS.zip(cells)]
      import_email = row["EMAIL"].downcase.strip
      import_user = User.find_or_create_by!(email: import_email)
      reservation = ClaimMembership.new(dublin_membership, customer: import_user).call
      Detail.create!(
        claim: reservation.active_claim,
        first_name: row["FNAME"],
        last_name: row["LNAME"],
        address_line_1: row["CITY"],
        city: row["CITY"],
        province: row["STATE"],
        country: row["COUNTRY"],
        show_in_listings: false,
        share_with_future_worldcons: false,
        publication_format: Detail::PAPERPUBS_ELECTRONIC,
      )
    end

    true
  end

  private

  def headings
    @headings ||= csv.first
  end

  def rows
    @rows ||= csv[1..-1]
  end

  def dublin_membership
    @dublin_membership ||= Membership.find_by!(name: :dublin_2019)
  end
end
