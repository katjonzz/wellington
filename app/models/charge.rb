# frozen_string_literal: true

# Copyright 2019 AJ Esler
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

# Charge represents some kind of payment either via a type of transfer, i.e. stripe or cash
# Reservation is associated with Charge to represent what payment went toward
# User is a ssociated with Charge to represent who owned the charge at the time
# 'cash' is a cludge which allows a Support login to credit a user if they mail in cheque or put cash into a lunchbox
# 'stripe' is a state machine which tracks payment via stripe
# 'stripe transfers' are breifly pending, then either successful or failed
class Charge < ApplicationRecord
  STATE_FAILED = "failed"
  STATE_SUCCESSFUL = "successful"
  STATE_PENDING = "pending"
  TRANSFER_STRIPE = "stripe"
  TRANSFER_CASH = "cash"

  belongs_to :user
  #belongs_to :reservation
  belongs_to :buyable, :polymorphic => true

  monetize :amount_cents

  validates :amount, presence: true
  validates :comment, presence: true
  validates :state, inclusion: {in: [STATE_FAILED, STATE_SUCCESSFUL, STATE_PENDING]}
  validates :stripe_id, presence: true, if: :stripe?
  validates :transfer, presence: true, inclusion: {in: [TRANSFER_STRIPE, TRANSFER_CASH]}

  scope :stripe, ->() { where(transfer: TRANSFER_STRIPE) }
  scope :cash, ->() { where(transfer: TRANSFER_CASH) }
  scope :pending, ->() { where(state: STATE_PENDING) }
  scope :failed, ->() { where(state: STATE_FAILED) }
  scope :successful, ->() { where(state: STATE_SUCCESSFUL) }

  def stripe?
    transfer == TRANSFER_STRIPE
  end

  def cash?
    transfer == TRANSFER_CASH
  end

  def successful?
    state == STATE_SUCCESSFUL
  end

  def pending?
    state == STATE_PENDING
  end

  def failed?
    state == STATE_FAILED
  end
end
