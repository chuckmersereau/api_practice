module ContactDonationMethods
  def designated_donations
    # Don't use the "donations" association as that may introduce duplicates and incorrect totals
    # if there are duplicated records in contact_donor_accounts.
    Donation.where(donor_account_id: donor_accounts.pluck(:id),
                   designation_account_id: account_list.designation_accounts.pluck(:id))
  end

  def last_donation
    designated_donations.first
  end

  def last_monthly_total
    designated_donations.where('donation_date >= ?', recent_avg_range_end.beginning_of_month).sum(:amount)
  end

  def prev_month_donation_date
    designated_donations.where('donation_date <= ?', (recent_avg_range_end << 1).end_of_month)
      .pluck(:donation_date).first
  end

  def recent_monthly_avg
    designated_donations
      .where('donation_date >= ?', recent_avg_range_start)
      .where('donation_date <= ?', recent_avg_range_end)
      .sum(:amount) /
      months_in_range(recent_avg_range_start, recent_avg_range_end)
  end

  def months_from_prev_to_last_donation
    return unless last_donation && prev_month_donation_date
    month_diff(prev_month_donation_date, last_donation.donation_date)
  end

  private

  def recent_avg_range_end
    @recent_avg_range_end ||=
        if last_donation_date && month_diff(last_donation_date, Date.today) > 0
          Date.today.prev_month.end_of_month
        else
          Date.today.end_of_month
        end
  end

  def recent_avg_range_start
    @recent_avg_range_start ||= begin
      start = [first_donation_date, Date.today << 12, prev_month_donation_date].compact.max
      months_in_range_mod_freq = months_in_range(start, recent_avg_range_end) % pledge_frequency
      start <<= pledge_frequency - months_in_range_mod_freq if months_in_range_mod_freq > 0
      start
    end
  end

  def month_diff(start_date, end_date)
    (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
  end

  def months_in_range(start_date, end_date)
    month_diff(start_date, end_date) + 1
  end
end
