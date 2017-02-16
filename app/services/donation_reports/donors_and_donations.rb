class DonationReports::DonorsAndDonations
  include ActiveModel::Model
  include ActiveModel::Serializers

  attr_accessor :donors, :donations
end
