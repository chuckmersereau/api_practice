class DonorAccountSerializer < ActiveModel::Serializer
  attributes :id, :organization_id, :account_number, :created_at, :updated_at, :total_donations,
             :last_donation_date, :first_donation_date, :donor_type, :contact_ids

  def contact_ids
    object.contacts.pluck(:id)
  end
end
