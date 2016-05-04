class DonationReports::DonorInfo
  include ActiveModel::Model
  include ActiveModel::SerializerSupport

  ATTRIBUTES = [
    :id, :name, :status, :pledge_amount, :pledge_frequency, :pledge_currency,
    :late_by_30_days, :late_by_60_days
  ].freeze
  attr_accessor(*ATTRIBUTES)

  def self.from_contact(contact)
    new(
      id: contact.id, name: contact.name, status: contact.status,
      pledge_amount: contact.pledge_amount,
      pledge_frequency: contact.pledge_frequency,
      pledge_currency: contact.pledge_currency,
      late_by_30_days: contact.late_by?(31, 60),
      late_by_60_days: contact.late_by?(60)
    )
  end
end
