class DonorAccountSerializer < ApplicationSerializer
  attributes :account_number,
             :contact_ids,
             :donor_type,
             :first_donation_date,
             :last_donation_date,
             :organization_id,
             :total_donations

  def contact_ids
    object.contacts.pluck(:id)
  end
end
