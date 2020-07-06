# frozen_string_literal: true

# Copyright 2019 AJ Esler
# Copyright 2020 Matthew B. Gray
# Copyright 2020 Victoria Garcia
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

module ApplicationHelper

  include ThemeConcern

  DEFUALT_NAV_CLASSES = %w(navbar navbar-dark shadow-sm).freeze

  # The root page has an expanded menu
  def navigation_classes
    if request.path == root_path
      DEFUALT_NAV_CLASSES
    else
      DEFUALT_NAV_CLASSES + %w(bg-dark)
    end.join(" ")
  end

  # These match i18n values set in config/locales
  # see Membership#all_rights
  def membership_right_description(membership_right, reservation)
    description = I18n.t(:description, scope: membership_right)
    if match = membership_right.match(/rights\.(.*)\.nominate\z/)
      election_i18n_key = match[1]
      link_to description, reservation_nomination_path(reservation_id: reservation, id: election_i18n_key)
    elsif match = membership_right.match(/rights\.(.*)\.nominate_only\z/)
      election_i18n_key = match[1]
      link_to description, reservation_nomination_path(reservation_id: reservation, id: election_i18n_key)
    else
      description
    end
  end

  def fuzzy_time(as_at)
    content_tag(
      :span,
      fuzzy_time_in_words(as_at),
      title: as_at&.iso8601 || "Time not set",
    )
  end

  def fuzzy_time_in_words(as_at)
    if as_at.nil?
      "open ended"
    elsif as_at < Time.now
      "#{time_ago_in_words(as_at)} ago"
    else
      "#{time_ago_in_words(as_at)} from now"
    end
  end

  def markdown
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
  end

  def worldcon_contact_form
    ApplicationHelper.theme_contact_form
  end

  def worldcon_public_name
    ApplicationHelper.theme_con_public_name
  end

  def worldcon_public_name_spaceless
    ApplicationHelper.theme_con_public_name.remove(" ");
  end

  def worldcon_year
    ApplicationHelper.theme_con_year
  end

  def site_selection_year
    ((ApplicationHelper.theme_con_year.to_i) + 2).to_s
  end

  def retro_hugo_year
    ((ApplicationHelper.theme_con_year.to_i) - 75).to_s
  end

  def email_hugo_help
    ApplicationHelper.theme_hugo_help_email
  end

  def worldcon_basic_greeting
    ApplicationHelper.theme_greeting
  end

  def worldcon_greeting_sentence
    ApplicationHelper.theme_greeting.capitalize.concat(".")
  end

  def worldcon_greeting_sentence_excited
    ApplicationHelper.theme_greeting.capitalize.concat("!")
  end

  def worldcon_greening_init_caps
    # TODO: Make this happen
  end

  def worldcon_city
    ApplicationHelper.theme_con_city
  end

  def worldcon_country
    ApplicationHelper.theme_con_country
  end



end
