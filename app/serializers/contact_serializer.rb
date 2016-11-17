class ContactSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper
  include ActionView::Helpers::NumberHelper

  # cached

  attributes :id, :name, :pledge_amount, :pledge_frequency, :pledge_currency, :pledge_currency_symbol, :pledge_start_date, :pledge_received, :status, :deceased,
             :notes, :notes_saved_at, :next_ask, :no_appeals, :likely_to_give, :church_name, :send_newsletter,
             :magazine, :last_activity, :last_appointment, :last_letter, :last_phone_call, :last_pre_call,
             :last_thank, :referrals_to_me_ids, :tag_list, :uncompleted_tasks_count, :timezone, :donor_accounts
end
