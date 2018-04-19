class Reports::ExpectedMonthlyTotals < ActiveModelSerializers::Model
  attr_accessor :account_list, :filter_params

  delegate :total_currency,
           :total_currency_symbol,
           to: :formatter

  def expected_donations
    (received + possible).map(&method(:format_donation_row))
  end

  private

  def received
    ExpectedTotalsReport::ReceivedDonations.new(
      account_list: account_list,
      filter_params: filter_params
    ).donation_rows
  end

  def possible
    ExpectedTotalsReport::PossibleDonations.new(
      account_list: account_list,
      filter_params: filter_params
    ).donation_rows
  end

  def format_donation_row(donation_row)
    formatter.format(donation_row)
  end

  def formatter
    @formatter ||= ExpectedTotalsReport::RowFormatter.new(account_list)
  end
end
