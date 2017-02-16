class DonationReports::DonationInfo < ActiveModelSerializers::Model
  ATTRIBUTES = [
    :amount,
    :contact_id,
    :contact_name,
    :converted_amount,
    :converted_currency,
    :currency,
    :donation_date,
    :donation_id,
    :likelihood_type
  ].freeze

  attr_accessor(*ATTRIBUTES)

  def self.from_donation(donation, default_currency = 'USD')
    new(
      amount: donation.tendered_amount || donation.amount,
      contact_id: donation.loaded_contact.try(:uuid),
      contact_name: donation.loaded_contact.try(:name),
      currency: donation.tendered_currency || donation.currency || default_currency,
      donation_date: donation.donation_date,
      donation_id: donation.uuid,
      likelihood_type: 'received'
    )
  end
end
