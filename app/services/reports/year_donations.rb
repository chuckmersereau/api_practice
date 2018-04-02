class Reports::YearDonations < ActiveModelSerializers::Model
  attr_accessor :account_list

  def donor_infos
    received_donations.donors
  end

  def donation_infos
    @donations = received_donations.donations
    DonationReports::DonationsConverter.new(account_list: account_list, donations: @donations).convert_amounts
    @donations
  end

  private

  def received_donations
    scoper = ->(donations) { donations.where('donation_date >= ?', 12.months.ago.beginning_of_month) }
    @received_donations ||= DonationReports::ReceivedDonations.new(account_list: account_list,
                                                                   donations_scoper: scoper)
  end
end
