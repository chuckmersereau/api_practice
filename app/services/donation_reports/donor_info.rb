class DonationReports::DonorInfo < ActiveModelSerializers::Model
  ATTRIBUTES = [
    :contact_id,
    :contact_name,
    :late_by_30_days,
    :late_by_60_days,
    :pledge_amount,
    :pledge_currency,
    :pledge_frequency,
    :status
  ].freeze

  attr_accessor(*ATTRIBUTES)

  def self.from_contact(contact)
    new(
      contact_id: contact.id,
      contact_name: contact.name,
      late_by_30_days: contact.late_by?(31, 60),
      late_by_60_days: contact.late_by?(60),
      pledge_amount: contact.pledge_amount,
      pledge_currency: contact.pledge_currency,
      pledge_frequency: contact.pledge_frequency,
      status: contact.status
    )
  end
end
