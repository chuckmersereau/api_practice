class DonationSerializer < ApplicationSerializer
  include LocalizationHelper

  attributes :amount,
             :appeal_amount,
             :appeal_id,
             :channel,
             :contact_id,
             :currency,
             :designation_account_id,
             :donation_date,
             :donor_account_id,
             :memo,
             :motivation,
             :payment_method,
             :payment_type,
             :remote_id,
             :tendered_amount,
             :tendered_currency

  def amount
    current_currency(scope[:account_list])
    number_to_current_currency(object.amount, locale: scope[:locale])
  end

  def contact_id
    object.donor_account.contacts.where(account_list_id: scope[:account_list].id).first.id
  end
end
