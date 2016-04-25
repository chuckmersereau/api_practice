class DonationReports::DonorsAndDonations
  include ActiveModel::Model
  include ActiveModel::SerializerSupport

  attr_accessor :donors, :donations
end
