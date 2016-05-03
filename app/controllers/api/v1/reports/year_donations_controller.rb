class Api::V1::Reports::YearDonationsController < Api::V1::BaseController
  def show
    within_one_year = lambda do |donations|
      donations.where('donation_date >= ?', 12.months.ago.beginning_of_month)
    end

    donations, donors =
      DonationReports::ReceivedDonations
      .new(account_list: current_account_list, donations_scoper: within_one_year)
      .donor_and_donation_info

    DonationReports::DonationsConverter
      .new(account_list: current_account_list, donations: donations)
      .convert_amounts

    render(
      json: DonationReports::DonorsAndDonations.new(
        donors: donors, donations: donations
      ),
      serializer: DonationReports::DonorsAndDonationsSerializer,
      root: :report_info
    )
  end
end
