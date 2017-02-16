class DonationsChart::MonthlyTotaler
  def initialize(account_list)
    @account_list = account_list
  end

  def months_back
    @months_back ||= calc_months_back
  end

  def totals
    currencies.map(&method(:totals_for_currency))
              .sort_by { |totals| totals[:total_converted] }
              .reverse
  end

  private

  attr_reader :account_list

  def calc_months_back
    first_donation = account_list.donations.select('donation_date').last
    return 1 unless first_donation

    first_donation_days_ago = Date.today.end_of_month - first_donation.donation_date
    approx_months = (first_donation_days_ago.to_f / 30).floor

    [[approx_months, 12].min, 1].max
  end

  def recent_donations
    account_list.donations.where('donation_date > ?',
                                 months_back.months.ago.utc.beginning_of_month)
  end

  def currencies
    # It is possible for some donations to have a `nil` value for their
    # currency, but that that is a rarer case and something we should fix
    # earlier in the process than here. What we do to handle that case is to
    # just ignore donations with no currencies to prevent an invalid call on
    # `nil` in the chart itself.
    @currencies ||= recent_donations.currencies.select(&:present?)
  end

  def totals_for_currency(currency)
    month_totals = currency_month_totals(currency)

    {
      currency: currency,
      total_amount: month_totals.map { |t| t[:amount] }.sum,
      total_converted: month_totals.map { |t| t[:converted] }.sum,
      month_totals: month_totals
    }
  end

  def currency_month_totals(currency)
    months_back.downto(0).map do |month_index|
      start_date = month_index.months.ago.utc.beginning_of_month
      end_date = start_date.end_of_month
      amount = account_list.donations
                           .where(currency: currency)
                           .where(donation_date: start_date..end_date)
                           .sum(:amount)

      mid_month = Date.new(start_date.year, start_date.month, 15)
      converted = CurrencyRate.convert_on_date(amount: amount, from: currency,
                                               to: total_currency, date: mid_month)

      { amount: amount, converted: converted }
    end
  end

  def total_currency
    account_list.salary_currency_or_default
  end
end
