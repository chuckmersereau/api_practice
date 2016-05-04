class DonationReports::DonationInfo
  include ActiveModel::Model
  include ActiveModel::SerializerSupport

  ATTRIBUTES = [
    :liklihood_type, :amount, :currency, :donation_date, :converted_amount,
    :converted_currency, :contact_id
  ].freeze
  attr_accessor(*ATTRIBUTES)

  def self.from_donation(donation, default_currency = 'USD')
    new(
      liklihood_type: 'received',
      amount: donation.tendered_amount || donation.amount,
      currency: donation.tendered_currency || donation.currency ||
        default_currency,
      donation_date: donation.donation_date,
      contact_id: donation.loaded_contact&.id
    )
  end
end
