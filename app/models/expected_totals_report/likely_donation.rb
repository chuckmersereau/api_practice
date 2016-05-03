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
    # Start with some basic checks of cases that make a gift unlikely
    return 0.0 if unlikely_by_fields?

    # The calculation will have a different basis depending on whether the
    # partner gives with a weekly basis (weekly or fortnightly) or a monthly
    # basis (month, quarterly, annual, etc.).
    # NOTE: if we add the "twice a month" as a pledge frequency in the future
    # this logic would need to be updated if we wanted to track that precisely
    # (right now it would be treated as fortnightly)
    if pledge_frequency < 1.0
      likely_more_weekly_base
    else
      likely_more_monthly_base
    end
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
  delegate :pledge_received?, :first_donation_date, :status, :pledge_amount,
           :pledge_frequency, :last_donation_date, to: :contact

  # Number of days of margin to allow for weekly gifts to still be considered
  # consistent, e.g. if the margin is 3, then we consider someone as consistent
  # for the past two weeks if they have two gifts in the past 2*7 + 3 = 17 days.
  WEEKLY_MARGIN_DAYS = 3

  # How many periods back to check for weekly / fortnightly donors.
  WEEKLY_PERIODS_BACK_TO_CHECK = 2

  # If the ministry partner has no pledge received, has no pledge, has never
  # given or has already given their full pledge this month, assume they will
  # not give any more this month.
  def unlikely_by_fields?
    !pledge_received? || pledge_amount.to_f.zero? || first_donation_date.nil? ||
      last_donation_date.nil? || @donations.empty? || pledge_frequency.nil?
  end

  # How much more the ministry partner is expected to give if their pledge
  # frequency basis is in weeks (weekly or fortnightly).
  def likely_more_weekly_base
    # Assume they will give zero if they didn't give recently
    pledge_frequency_weeks = (pledge_frequency / weekly_frequency).round
    return 0.0 unless gave_in_recent_weekly_periods?(pledge_frequency_weeks)

    # Extrapolate the expected remaining they will give based on how many giving
    # periods are left in the month.
    periods_left_in_month(pledge_frequency_weeks) * pledge_amount
  end

  def periods_left_in_month(pledge_frequency_weeks)
    (days_left_in_month / 7 / pledge_frequency_weeks).floor
  end

  def days_left_in_month
    Time.days_in_month(@date_in_month.month, @date_in_month.year) -
      @date_in_month.day
  end

  # Checks whether the ministry partner gave consistently in recent periods that
  # have a weekly base. This is a fairly simple calculation for now that just
  # checks whether a partner total gifts is at least their pledge over the
  # recent period range.
  def gave_in_recent_weekly_periods?(pledge_frequency_weeks)
    # Add in a couple of margin days in case it takes a couple of days to
    # process the weekly / fortnightly gifts.
    days_back_to_check = pledge_frequency_weeks * 7 * WEEKLY_PERIODS_BACK_TO_CHECK +
                         WEEKLY_MARGIN_DAYS

    recent_total = sum_over_date_range(@date_in_month - days_back_to_check, @date_in_month)

    recent_total >= pledge_amount * WEEKLY_PERIODS_BACK_TO_CHECK
  end

  def weekly_frequency
    Contact.pledge_frequencies.keys.first
  end

  def sum_over_date_range(from, to)
    @donations.select { |d| d.donation_date >= from && d.donation_date <= to }
              .sum(&:amount)
  end

  def likely_more_monthly_base
    # Do some basic checks first for common cases when we would assume a partner
    # will not give any more this month.
    return 0.0 if received_this_month >= pledge_amount || unlikely_by_donation_history?

    # Assuming there isn't anything in the fields or the donation history that
    # indicates that this partner would be unlikely to give this month, then
    # by default assume they will give their pledge amount minus what they gave so
    # far. This can happen e.g. if a contact gives $100/mo but they give twice
    # per month. Then at one part of the month they have given $50, so assuming
    # they are consistent, at that opint the likely amount more is still $50.
    amount_under_pledge_this_month
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
    last_gift_months_ago != pledge_frequency.to_i
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
      gave_by_recurring_channel?(months_back: pledge_frequency.to_i)
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
      months_ago = (periods_back_index + 1) * pledge_frequency.to_i
      donations_total(months_ago: months_ago)
    end
    total_for_periods >= pledge_amount * periods_back
  end

  def first_donation_periods_back
    months_ago(first_donation_date) / pledge_frequency.to_i
  end

  def periods_below_pledge(periods_back:)
    periods_back.times.count do |periods_back_index|
      months_ago = (periods_back_index + 1) * pledge_frequency.to_i
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
    @current_month_index ||= month_index(@date_in_month)
  end

  def month_index(date)
    date.year * 12 + date.month
  end
end
