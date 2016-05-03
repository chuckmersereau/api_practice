class DonationReports::DonationsConverter
  def initialize(donations:, account_list:)
    @donations = donations
    @account_list = account_list
  end

  def convert_amounts
    donation_currencies.each do |currency|
      CurrencyRate.cache_rates_for_dates(
        currency_code: currency, from_date: min_donation_date,
        to_date: max_donation_date)
    end
    @donations.each(&method(:convert_donation))
  end

  private

  def convert_donation(donation)
    donation.converted_amount = CurrencyRate.convert_on_date(
      amount: donation.amount, from: donation.currency, to: total_currency,
      date: donation.donation_date)
    donation.converted_currency = total_currency
  end

  def total_currency
    @total_currency ||= @account_list.salary_currency_or_default
  end

  def donation_currencies
    @donations.map(&:currency).uniq
  end

  def min_donation_date
    @min_donation_date ||= donation_dates.min
  end

  def max_donation_date
    @min_donation_date ||= donation_dates.max
  end

  def donation_dates
    @donation_dates ||= @donations.map(&:donation_date)
  end
end
