class DonationSerializer < ApplicationSerializer
  include LocalizationHelper

  attributes :amount,
             :appeal_amount,
             :channel,
             :converted_amount,
             :converted_appeal_amount,
             :converted_currency,
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

  def contact
    return unless scope&.[](:account_list)

    object.donor_account.contacts.where(account_list: scope[:account_list]).first
  end
end
