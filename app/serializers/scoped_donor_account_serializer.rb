class ScopedDonorAccountSerializer < ApplicationSerializer
  type :donor_accounts

  delegate :account_number,
           :contacts,
           :created_at,
           :donor_type,
           :first_donation_date,
           :last_donation_date,
           :organization,
           :total_donations,
           :updated_at,
           :uuid,
           to: :object

  attributes :account_number,
             :donor_type,
             :first_donation_date,
             :last_donation_date,
             :total_donations

  belongs_to :organization
  has_many :contacts
end
