class ContactSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper
  include ActionView::Helpers::NumberHelper

  attributes :avatar,
             :church_name,
             :deceased,
             :direct_deposit,
             :envelope_greeting,
             :greeting,
             :last_activity,
             :last_appointment,
             :last_donation,
             :last_letter,
             :last_phone_call,
             :last_pre_call,
             :last_thank,
             :late_at,
             :likely_to_give,
             :locale,
             :magazine,
             :name,
             :next_ask,
             :no_appeals,
             :no_gift_aid,
             :notes,
             :notes_saved_at,
             :pledge_amount,
             :pledge_currency,
             :pledge_currency_symbol,
             :pledge_frequency,
             :pledge_received,
             :pledge_start_date,
             :send_newsletter,
             :square_avatar,
             :status,
             :status_valid,
             :suggested_changes,
             :tag_list,
             :timezone,
             :uncompleted_tasks_count,
             :website

  belongs_to :account_list

  has_many :addresses
  has_many :appeals
  has_many :contact_referrals_by_me
  has_many :contact_referrals_to_me
  has_many :contacts_referred_by_me
  has_many :contacts_that_referred_me
  has_many :donor_accounts
  has_many :last_six_donations
  has_many :people
  has_many :tasks

  has_one :primary_person
  has_one :primary_or_first_person
  has_one :spouse

  def avatar
    contact_exhibit.avatar(:large)
  end

  def square_avatar
    contact_exhibit.avatar
  end

  def pledge_frequency
    number_with_precision(object[:pledge_frequency], precision: 14, strip_insignificant_zeros: true)
  end

  def contact_exhibit
    ContactExhibit.new(object, self)
  end

  def account_list_id
    object.account_list.uuid
  end

  def tag_list
    object.tags.collect(&:name)
  end
end
