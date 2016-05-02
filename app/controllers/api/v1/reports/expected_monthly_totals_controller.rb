class Api::V1::Reports::ExpectedMonthlyTotalsController < Api::V1::BaseController
  def show
    render json: {
      donations: (received + possible).map(&method(:format_donation_row)),
      total_currency: formatter.total_currency,
      total_currency_symbol: formatter.total_currency_symbol
    }.to_json
  end

  private

  def received
    ExpectedTotalsReport::ReceivedDonations.new(current_account_list).donation_rows
  end

  def possible
    ExpectedTotalsReport::PossibleDonations.new(current_account_list).donation_rows
  end

  def format_donation_row(donation_row)
    formatter.format(donation_row)
  end

  def formatter
    @formatter ||= ExpectedTotalsReport::RowFormatter.new(current_account_list)
  end
end
