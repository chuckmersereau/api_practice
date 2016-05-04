class DonationReports::DonorsAndDonationsSerializer < ActiveModel::Serializer
  has_many :donors
  has_many :donations
end
