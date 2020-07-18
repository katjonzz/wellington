# Copyright 2020 Matthew B. Gray
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

# Operator::UsersController is the CoNZealand admin for virtual attendance
# It integartes with a 3rd party login provider called Gloo
class Operator::UsersController < ApplicationController
  before_action :authenticate_operator!
  before_action :lookup_user!, except: :index
  before_action :lookup_gloo_contact!, except: :index

  def index
  end

  def show
  end

  def update
    @gloo_contact.save!
    flash[:notice] = just_saved_message
    redirect_to operator_user_path(@user)
  end

  private

  def just_saved_message
    if membership_number = @gloo_contact.reservation&.membership_number
      "Pushed #{@user.email} to TFN with membership ##{membership_number}"
    else
      "Disabled #{@user.email} on TFN"
    end
  end
end
