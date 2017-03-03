class DonorAccountSerializer < ApplicationSerializer
  attributes :account_number,
             :donor_type,
             :first_donation_date,
             :last_donation_date,
             :total_donations

  belongs_to :organization
end
