# frozen_string_literal: true

# Copyright 2020 Matthew B. Gray
# Copyright 2019 AJ Esler
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

class ReservationsController < ApplicationController
  include ThemeConcern

  before_action :lookup_reservation!, only: %i[show update]
  before_action :lookup_offer, only: %i[new create reserve_with_cheque]
  before_action :setup_paperpubs, except: :index

  # TODO(issue #24) list all members for people not logged in
  def index
    if user_signed_in?
      @my_purchases = Reservation.joins(:user).where(users: { id: current_user })
      @my_purchases = @my_purchases.joins(:membership)
      @my_purchases = @my_purchases.includes(:charges).includes(active_claim: :contact)
    end
  end

  def new
    @reservation = Reservation.new
    @contact = contact_model.new.for_user(current_user)
    @offers = MembershipOffer.options
    if user_signed_in?
      @current_memberships = MembershipsHeldSummary.new(current_user).to_s
    else
      session[:return_path] = request.fullpath
    end
  end

  def show
    @contact = @reservation.active_claim.contact || contact_model.new
    @my_offer = MembershipOffer.new(@reservation.membership)
    @outstanding_amount = AmountOwedForReservation.new(@reservation).amount_owed
    @notes = Note.joins(user: :claims).where(claims: { reservation_id: @reservation })
    @rights_exhausted = RightsExhausted.new(@reservation).call
    get_payment_history
  end

  def create
    create_and do |new_reservation|
      flash[:notice] = %(
        Congratulations member #{new_reservation.membership_number}!
        You've just reserved a #{@my_offer.membership} membership
      )

      if new_reservation.membership.price.zero?
        redirect_to reservations_path
      else
        redirect_to new_reservation_charge_path(new_reservation)
      end
    end
  end

  def reserve_with_cheque
    create_and do |new_reservation|
      flash[:notice] = %(
        You've just reserved a #{@my_offer.membership} membership. See your email for instructions on payment by cheque.
      )

      PaymentMailer.waiting_for_cheque(
        user: current_user,
        reservation: new_reservation,
        outstanding_amount: AmountOwedForReservation.new(new_reservation).amount_owed.format(with_currrency: true)
      ).deliver_later

      new_reservation.state = Reservation::INSTALMENT

      redirect_to reservations_path
    end
  end

  def update
    @reservation.transaction do
      current_contact = @reservation.active_claim.contact
      current_contact ||= contact_model.new(claim: @reservation.active_claim)
      submitted_values = contact_params
      if current_contact.update(submitted_values)
        flash[:notice] = "Details for #{current_contact} member ##{@reservation.membership_number} have been updated"
        redirect_to reservations_path
      else
        @contact = @reservation.active_claim.contact || contact_model.new
        @my_offer = MembershipOffer.new(@reservation.membership)
        @outstanding_amount = AmountOwedForReservation.new(@reservation).amount_owed
        get_payment_history
        flash[:error] = current_contact.errors.full_messages.to_sentence
        render "reservations/show"
      end
    end
  end

  private

  def create_and
    new_reservation = current_user.transaction do
      @contact = contact_model.new(contact_params)
      @contact.date_of_birth = convert_dateselect_params_to_date if dob_params_present?
      unless @contact.valid?
        @reservation = Reservation.new
        flash[:error] = @contact.errors.full_messages.to_sentence(words_connector: ", and ").humanize.concat(".")
        render "/reservations/new"
        return
      end

      service = ClaimMembership.new(@my_offer.membership, customer: current_user)
      new_reservation = service.call
      @contact.claim = new_reservation.active_claim
      @contact.save!

      new_reservation
    end

    yield new_reservation
  end

  def lookup_offer
    @my_offer = MembershipOffer.options.find do |offer|
      offer.hash == params[:offer]
    end
    unless @my_offer.present?
      flash[:error] = t("errors.offer_unavailable", offer: params[:offer])
      redirect_back(fallback_location: memberships_path)
      # redirect_to memberships_path
    end
  end

  def setup_paperpubs
    @paperpubs = contact_model::PAPERPUBS_OPTIONS.map { |o| [o.humanize, o] }
  end

  def contact_params
    params.require(theme_contact_param).permit(theme_contact_class.const_get("PERMITTED_PARAMS"))
  end

  def contact_model
    Claim.contact_strategy
  end

  def convert_dateselect_params_to_date
    key1 = "dob_array(1i)"
    key2 = "dob_array(2i)"
    key3 = "dob_array(3i)"
    Date.new(params[theme_contact_param][key1].to_i, params[theme_contact_param][key2].to_i,
             params[theme_contact_param][key3].to_i)
  end

  def dob_params_present?
    dob_key_1 = "dob_array(1i)"
    params[theme_contact_param].key?(dob_key_1)
  end

  def get_payment_history
    @reservation ||= lookup_reservation!
    payment_history_obj = ReservationPaymentHistory.new(@reservation)
    @any_successful_charges = payment_history_obj.any_charges?
    @payment_history = payment_history_obj.history_array
    @successful_charges_found = payment_history_obj.any_successful_charges?
  end
end
