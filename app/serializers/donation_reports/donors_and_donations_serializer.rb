class DonationReports::DonorsAndDonationsSerializer < ApplicationSerializer
  has_many :donations
  has_many :donors
end
