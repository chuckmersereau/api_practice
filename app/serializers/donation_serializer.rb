class DonationSerializer < ApplicationSerializer
  include LocalizationHelper

  attributes :amount,
             :appeal_amount,
             :channel,
             :currency,
             :donation_date,
             :memo,
             :motivation,
             :payment_method,
             :payment_type,
             :remote_id,
             :tendered_amount,
             :tendered_currency

  belongs_to :appeal
  belongs_to :contact
  belongs_to :designation_account
  belongs_to :donor_account

  def amount
    return unless scope
    current_currency(scope[:account_list])
    number_to_current_currency(object.amount, locale: scope[:locale])
  end

  def contact
    return unless scope
    object.donor_account.contacts.where(account_list_id: scope[:account_list].id).first
  end
end
