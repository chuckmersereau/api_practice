class ContactSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper
  include ActionView::Helpers::NumberHelper

  attributes :avatar,
             :church_name,
             :deceased,
             :donor_accounts,
             :last_activity,
             :last_appointment,
             :last_letter,
             :last_phone_call,
             :last_pre_call,
             :last_thank,
             :likely_to_give,
             :magazine,
             :name,
             :next_ask,
             :no_appeals,
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
             :tag_list,
             :timezone,
             :uncompleted_tasks_count

  has_many :addresses
  has_many :people
  has_many :referrals_to_me
  belongs_to :account_list

  def avatar
    contact_exhibit.avatar(:large)
  end

  def square_avatar
    contact_exhibit.avatar
  end

  def pledge_received
    object[:pledge_received].to_s
  end

  def pledge_frequency
    number_with_precision(object[:pledge_frequency], precision: 14, strip_insignificant_zeros: true)
  end

  def contact_exhibit
    exhibit(object)
  end
end
