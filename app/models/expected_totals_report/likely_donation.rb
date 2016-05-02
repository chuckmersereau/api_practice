class ExpectedTotalsReport::LikelyDonation
  def initialize(contact:, recent_donations:, date_in_month:)
    @contact = contact
    @donations = recent_donations
    @date_in_month = date_in_month
  end

  # How much the contact has already given this month
  def received_this_month
    @received_this_month ||= donations_total(months_ago: 0)
  end

  # How much we expect the contact will give more this month based on the logic
  # below.
  def likely_more
    # Do some basic checks first for common cases when we would assume a partner
    # will not give any more this month.
    return 0.0 if unlikely_by_fields? || unlikely_by_donation_history?

    # Assuming there isn't anything in the fields or the donation history that
    # indicates that this partner would be unlikely to give this month, then
    # by default assume they will give their pledge amount minus what they gave so
    # far. This can happen e.g. if a contact gives $100/mo but they give twice
    # per month. Then at one part of the month they have given $50, so assuming
    # they are consistent, at that opint the likely amount more is still $50.
    amount_under_pledge_this_month
  end

  private

  # How many months back to check for monthly partners in order to determine
  # whether they have enough track record to be considered a likely donor under
  # certain circumstances (e.g. if they gave a partial amount this month).
  MONTHS_BACK_TO_CHECK_FOR_MONTHLY = 3

  # How many periods of gifts up to their pledge do we require for annual /
  # biennial donors for them to be considered likely donors assuming they are
  # not giving via a Recurring channel.
  LONG_TIME_FRAME_NON_RECURRING_TRACK_RECORD_PERIODS = 2

  attr_reader :contact
  delegate :pledge_received?, :first_donation_date, :status,
           :last_donation_date, to: :contact

  # If the ministry partner has no pledge received, has no pledge, has never
  # given or has already given their full pledge this month, assume they will
  # not give any more this month.
  def unlikely_by_fields?
    !pledge_received? || pledge_amount.to_f.zero? || first_donation_date.nil? ||
      last_donation_date.nil? || @donations.empty? ||
      received_this_month >= pledge_amount
  end

  # Use slightly different logic for using the donation history to identify
  # partners unlikely to give this month.
  def unlikely_by_donation_history?
    if pledge_frequency <= 1
      unlikely_for_monthly?
    elsif pledge_frequency <= 3
      unlikely_for_bi_monthly_or_quarterly?
    else
      unlikely_for_long_time_frame?
    end
  end

  # For monthly donors, consider a few different scenarios as monthly donors may
  # sometimes miss a month and then make it up later.
  def unlikely_for_monthly?
    gave_less_this_month_and_not_much_track_record? ||
      multiple_giving_gaps_recently? ||
      behind_on_pledge_recently?
  end

  def gave_less_this_month_and_not_much_track_record?
    received_this_month > 0.0 &&
      received_this_month < pledge_amount &&
      !given_pledge_in_past?(periods_back: MONTHS_BACK_TO_CHECK_FOR_MONTHLY)
  end

  def multiple_giving_gaps_recently?
    # A giving cap only occurs if the partner had previously started their
    # giving. Someone who gave for the first time last month has no giving gaps.
    had_gift_in_further_past? && multiple_recent_months_below_pledge?
  end

  def had_gift_in_further_past?
    month_index(first_donation_date) <=
      month_index(MONTHS_BACK_TO_CHECK_FOR_MONTHLY.months.ago)
  end

  def multiple_recent_months_below_pledge?
    periods_below_pledge(periods_back: MONTHS_BACK_TO_CHECK_FOR_MONTHLY) > 1
  end

  def behind_on_pledge_recently?
    !averaging_to_pledge?(periods_back: MONTHS_BACK_TO_CHECK_FOR_MONTHLY)
  end

  # For bi-monthly (every other month) and quarterly donors, just look at
  # whether they gave their last the same number of months ago as their pledge
  # frequency, i.e. 3 months ago for quarterly or 2 months ago for bi-monthly.
  # That will indicate that this month is the month they give and that we should
  # expect them to give. This isn't really as complete of a check as the monthly
  # cases above but it's a decent first approximation.
  def unlikely_for_bi_monthly_or_quarterly?
    last_gift_months_ago = months_ago(last_donation_date)
    last_gift_months_ago != pledge_frequency
  end

  # For long time frame donors (every 6, 12 or 24 months), take the stance that
  # they probably won't give unless they have enough track record. Specifically,
  # we consider they have enough track record if their past gift was Recurring
  # or if they had two on-time full-pledge gifts in the past two periods.
  def unlikely_for_long_time_frame?
    !enough_track_record_for_long_time_frame_partner? &&
      !gave_on_time_last_period_and_by_recurring_channel?
  end

  def enough_track_record_for_long_time_frame_partner?
    given_pledge_in_past?(
      periods_back: LONG_TIME_FRAME_NON_RECURRING_TRACK_RECORD_PERIODS)
  end

  def gave_on_time_last_period_and_by_recurring_channel?
    given_pledge_in_past?(periods_back: 1) &&
      gave_by_recurring_channel?(months_back: pledge_frequency)
  end

  def gave_by_recurring_channel?(months_back:)
    @donations.any? do |donation|
      months_ago(donation.donation_date) == months_back &&
        donation.channel == 'Recurring'
    end
  end

  def amount_under_pledge_this_month
    [0.0, pledge_amount - donations_total(months_ago: 0)].max
  end

  def given_pledge_in_past?(periods_back:)
    periods_below_pledge(periods_back: periods_back) == 0
  end

  def averaging_to_pledge?(periods_back:)
    periods_back = [periods_back, first_donation_periods_back].min
    total_for_periods = periods_back.times.sum do |periods_back_index|
      months_ago = (periods_back_index + 1) * pledge_frequency
      donations_total(months_ago: months_ago)
    end
    total_for_periods >= pledge_amount * periods_back
  end

  def first_donation_periods_back
    months_ago(first_donation_date) / pledge_frequency
  end

  def periods_below_pledge(periods_back:)
    periods_back.times.count do |periods_back_index|
      months_ago = (periods_back_index + 1) * pledge_frequency
      donations_total(months_ago: months_ago) < pledge_amount
    end
  end

  def donations_total(months_ago:)
    @totals_by_months_ago ||= calc_totals_by_months_ago
    @totals_by_months_ago[months_ago] || 0.0
  end

  def calc_totals_by_months_ago
    @donations.each_with_object({}) do |donation, totals_by_month|
      months_ago = months_ago(donation.donation_date)
      totals_by_month[months_ago] ||= 0.0
      totals_by_month[months_ago] += donation.tendered_amount
    end
  end

  def months_ago(date)
    current_month_index - month_index(date)
  end

  def current_month_index
    @current_month_index ||= month_index(Date.current)
  end

  def month_index(date)
    date.year * 12 + date.month
  end

  def pledge_frequency
    # For simplicity, model weekly and bi-weekly donors as their average monthly
    @pledge_frequency ||=
      @contact.pledge_frequency < 1.0 ? 1 : @contact.pledge_frequency.to_i
  end

  def pledge_amount
    return 0.0 if @contact.pledge_frequency.nil?
    # For simplicity, model weekly and bi-weekly donors as their average monthly
    @pledge_amount ||=
      if @contact.pledge_frequency < 1.0
        @contact.monthly_pledge
      else
        @contact.pledge_amount
      end
  end
end
