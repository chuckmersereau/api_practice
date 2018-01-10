class Reports::DonorCurrencyDonations < ActiveModelSerializers::Model
  include Concerns::Reports::DonationSumHelper

  MONTHS_BACK = 12

  attr_accessor :account_list

  def donor_infos
    received_donations_object.donors
  end

  def months
    @months ||=
      MONTHS_BACK.downto(0).map { |i| i.months.ago.to_date.beginning_of_month }
  end

  def currency_groups
    Hash.new { |h, k| h[k] = {} }.tap do |grouped|
      donations_by_currency(all_received_donations).each do |currency, donations|
        grouped[currency] = {
          totals: {
            year: sum_donations(donations),
            year_converted: sum_converted_donations(donations, account_list.salary_currency),
            months: sum_donations_by_month(donations, months)
          },
          donation_infos: contacts_donation_info(donations)
        }
      end
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

  def contacts_donation_info(all_donations)
    donor_infos
      .map { |donation| create_donation_info(donation, all_donations) }
      .reject { |info| info[:months].empty? }
  end

  def create_donation_info(donor, all_donations)
    id = donor.contact_id
    contact_donations = all_donations.select { |d| d.contact_id == id }
    amounts = contact_donations.map { |d| donation_amount(d) }
    total = amounts.inject(:+)
    {
      contact_id: id,
      total: total,
      average: (total / amounts.size.to_f if total),
      minimum: amounts.min,
      maximum: amounts.max,
      months: summarize_months(contact_donations)
    }
  end

  def summarize_months(all_donations)
    group_donations_by_month(all_donations, months).map do |donations|
      {
        total: sum_donations(donations),
        donations: donations
      }
    end
  end

  def received_donations_object
    @received_donations_object ||=
      DonationReports::ReceivedDonations.new(
        account_list: account_list,
        donations_scoper: ->(donation) { donation.where('donation_date >= ?', start_date) }
      )
  end

  def start_date
    @start_date ||= MONTHS_BACK.months.ago.beginning_of_month
  end

  def all_received_donations
    @all_received_donations ||= received_donations_object.donations
  end
end
