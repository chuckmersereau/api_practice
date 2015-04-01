module ContactDonationMethods
  def donations
    Donation.where(donor_account_id: donor_accounts.pluck(:id))
      .for_accounts(account_list.designation_accounts)
  end

  def last_donation
    donations.first
  end

  def last_monthly_total
    donations.where('donation_date >= ?', last_donation_month_end.beginning_of_month).sum(:amount)
  end

  def prev_month_donation_date
    donations.where('donation_date <= ?', (last_donation_month_end << 1).end_of_month)
      .pluck(:donation_date).first
  end

  def monthly_avg_current
    prev_months_to_include = [(pledge_frequency || 1) - 1, 0].max
    start_date = (last_donation_month_end << prev_months_to_include).beginning_of_month
    monthly_avg_over_range(start_date, last_donation_month_end)
  end

  def monthly_avg_with_prev_gift
    monthly_avg_over_range(prev_donation_month_start, last_donation_month_end)
  end

  def months_from_prev_to_last_donation
    return unless last_donation && prev_month_donation_date
    month_diff(prev_month_donation_date, last_donation.donation_date)
  end

  def monthly_avg_from(date)
    return unless date
    monthly_avg_over_range(start_of_pledge_interval(date), last_donation_month_end)
  end

  private

  def monthly_avg_over_range(start_date, end_date)
    donations
      .where('donation_date >= ?', start_date)
      .where('donation_date <= ?', end_date)
      .sum(:amount) /
      months_in_range(start_date, end_date)
  end

  def last_donation_month_end
    @recent_avg_range_end ||=
      if last_donation_date && month_diff(last_donation_date, Date.today) > 0
        Date.today.prev_month.end_of_month
      else
        Date.today.end_of_month
      end
  end

  def prev_donation_month_start
    @prev_donation_month_start ||=
      start_of_pledge_interval([first_donation_date, Date.today << 12,
                                prev_month_donation_date].compact.max)
  end

  def start_of_pledge_interval(date)
    months_in_range_mod_freq = months_in_range(date, last_donation_month_end) % pledge_frequency
    months_to_subtract = months_in_range_mod_freq == 0 ? 0 : pledge_frequency - months_in_range_mod_freq
    (date << months_to_subtract).beginning_of_month
  end

  def month_diff(start_date, end_date)
    (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
  end

  def months_in_range(start_date, end_date)
    month_diff(start_date, end_date) + 1
  end
end
