module Concerns::Reports::DonationSumHelper
  protected

  def donation_currency(donation)
    donation.currency
  end

  def donation_amount(donation)
    donation.amount
  end

  def donoations_with_currency(donations)
    donations.currencies.select(&:present?).map do |currency|
      donos     = donations.where(currency: currency)
      converted = donos.map(&:converted_amount).inject(:+) || 0
      {
        amount:     donos.sum(:amount),
        converted:  converted,
        currency:   currency
      }
    end
  end

  private

  def donations_by_currency(donations)
    Hash.new { |hash, key| hash[key] = [] }.tap do |grouped|
      donations.each do |donation|
        grouped[donation_currency(donation)].push(donation)
      end
    end
  end

  def sum_donations(donations)
    donations.map(&:amount).inject(:+) || 0
  end

  def sum_converted_donations(donations, converted_currency = 'USD')
    donations.map do |donation|
      CurrencyRate.convert_on_date(
        amount: donation.amount,
        date: donation.donation_date,
        from: donation.currency,
        to: converted_currency
      )
    end.inject(:+) || 0
  end

  def sum_donations_by_month(donations, months)
    group_donations_by_month(donations, months).map { |donation| sum_donations(donation) }
  end

  def group_donations_by_month(donations, months)
    months.map do |month|
      donations.select { |donation| donation.donation_date.beginning_of_month == month }
    end
  end
end
