module Concerns::Reports::DonationSumHelper
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

  def sum_converted_donations(donations)
    donations.map(&:converted_amount).inject(:+) || 0
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
