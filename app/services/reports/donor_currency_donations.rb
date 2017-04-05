class Reports::DonorCurrencyDonations < ActiveModelSerializers::Model
  MONTHS_BACK = 12

  attr_accessor :account_list

  def donor_infos
    received_donations.donors
  end

  def months
    @months ||=
      MONTHS_BACK.downto(0).map { |i| i.months.ago.to_date.beginning_of_month }
  end

  def currency_groups
    Hash.new { |h, k| h[k] = {} }.tap do |grouped|
      donations_by_currency.each do |currency, donations|
        grouped[currency] = {
          totals: {
            year: sum_donations(donations),
            year_converted: sum_converted_donations(donations),
            months: sum_donations_by_month(donations)
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
      .map { |d| create_donation_info(d, all_donations) }
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
    group_donations_by_month(all_donations).map do |donations|
      {
        total: sum_donations(donations),
        donations: donations
      }
    end
  end

  def received_donations
    @received_donations ||=
      DonationReports::ReceivedDonations.new(
        account_list: account_list,
        donations_scoper: ->(d) { d.where('donation_date >= ?', start_date) }
      )
  end

  def start_date
    @start_date ||= MONTHS_BACK.months.ago.beginning_of_month
  end

  def donations_by_currency
    Hash.new { |h, k| h[k] = [] }.tap do |grouped|
      donations.each do |donation|
        grouped[donation_currency(donation)].push(donation)
      end
    end
  end

  def donations
    @donations ||= received_donations.donations
  end

  def sum_donations(donations)
    donations.map(&:amount).inject(:+) || 0
  end

  def sum_converted_donations(donations)
    donations.map(&:converted_amount).inject(:+) || 0
  end

  def sum_donations_by_month(donations)
    group_donations_by_month(donations).map { |d| sum_donations(d) }
  end

  def group_donations_by_month(donations)
    months.map do |month|
      donations.select { |d| d.donation_date.beginning_of_month == month }
    end
  end
end
