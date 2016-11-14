class DonationSerializer < ActiveModel::Serializer
  include LocalizationHelper

  attributes :id, :amount, :donation_date, :contact_id, :appeal_id, :appeal_amount, :donor_account_id,
             :designation_account_id, :remote_id, :motivation, :payment_method, :tendered_currency, :tendered_amount,
             :currency, :memo, :payment_type, :channel

  def amount
    account_list = scope[:account_list]
    current_currency(account_list)

    number_to_current_currency(object.amount, locale: scope[:locale])
  end

  def contact_id
    object.donor_account.contacts.where(account_list_id: scope[:account_list].id).first.id
  end
end
