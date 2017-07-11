class Reports::DonationMonthlyTotals < ActiveModelSerializers::Model
  include Concerns::Reports::DonationSumHelper

  attr_accessor :account_list,
                :end_date,
                :start_date,
                :months

  validates :account_list, :start_date, :end_date, presence: true

  def initialize(account_list:, start_date:, end_date:)
    super
    date_range = start_date.beginning_of_month.to_datetime..end_date.beginning_of_month.to_datetime
    @months = date_range.map { |date| Date.new(date.year, date.month, 1) }.uniq
  end

  def donation_totals_by_month
    donations_by_month = group_donations_by_month(all_received_donations, months)

    months.each_with_index.map do |month, month_index|
      {
        month: month.to_date,
        totals_by_currency: amounts_by_currency(donations_by_month[month_index])
      }
    end
  end

  protected

  def donation_currency(donation)
    donation.currency
  end

  def donation_amount(donation)
    donation.amount
  end

  private

  def amounts_by_currency(donations_for_one_month)
    donations_by_currency(donations_for_one_month).map do |currency, donations|
      {
        donor_currency: currency,
        total_in_donor_currency: sum_donations(donations),
        converted_total_in_salary_currency: sum_converted_donations(donations)
      }
    end
  end

  def all_received_donations
    @all_received_donations = received_donations_object.donations
  end

  def received_donations_object
    @received_donations_object ||=
      DonationReports::ReceivedDonations.new(
        account_list: account_list,
        donations_scoper: ->(donation) { donation.where(donation_date: @months.first..@months.last.end_of_month) }
      )
  end
end
