# frozen_string_literal: true

# Copyright 2021 Victoria Garcia
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

FactoryBot.define do
  factory :cart_chassis do

    transient do
      now_bin { create(:cart, :with_basic_items, status: "for_now")}
      later_bin { create(:cart, :with_basic_items, status: "for_now")}
    end

    after(:build) do |cart_chassis, evaluator|
      cart_chassis.now_bin = evaluator.now_bin
      cart_chassis.later_bin = evaluator.later_bin
    end

    skip_create
  end
end