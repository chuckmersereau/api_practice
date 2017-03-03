class ScopedDonorAccount < ActiveModelSerializers::Model
  attr_accessor :account_list, :donor_account

  delegate :account_number,
           :created_at,
           :donor_type,
           :first_donation_date,
           :last_donation_date,
           :organization,
           :total_donations,
           :updated_at,
           :uuid,
           to: :donor_account

  def initialize(account_list:, donor_account:)
    @account_list = account_list
    @donor_account = donor_account
  end

  def contacts
    donor_account.contacts.where(account_list: account_list)
  end
end
