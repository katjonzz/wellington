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

RSpec.describe Charge, type: :model do
  subject(:model) { create(:charge) }

  it { is_expected.to be_valid }

  # If this is failing
  # And CoNZealand is no longer running
  # Please feel free to backspace this entire block
  context "after #sync_with_glue called" do
    # it's an after_commit hook, so executes after save
    after { create(:charge) }

    it "dosn't call GlueSync outside of conzealand" do
      Rails.configuration.contact_model = "dc"
      ENV["GLUE_BASE_URL"] = "https://api.thefantasy.network/v1"
      expect(GlueSync).to_not receive(:perform_async)
    end

    it "doesn't call GlueSync when not configured" do
      Rails.configuration.contact_model = "conzealand"
      ENV["GLUE_BASE_URL"] = nil
      expect(GlueSync).to_not receive(:perform_async)
    end

    it "calls when confgured in conzealand" do
      Rails.configuration.contact_model = "conzealand"
      ENV["GLUE_BASE_URL"] = "https://api.thefantasy.network/v1"
      expect(GlueSync).to receive(:perform_async)
    end
  end
end
