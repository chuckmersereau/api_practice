module ContactStatusSuggesterSpecHelpers
  def create_donations_to_match_frequency(pledge_frequency, one_time: true)
    pledge_frequency_in_days = (pledge_frequency * 30).round

    # Create consistent donations according to the given pledge_frequency
    (1..Contact::StatusSuggester::NUMBER_OF_DONATIONS_TO_SAMPLE).each do |multiplier|
      create_donation_with_details(50, (multiplier * pledge_frequency_in_days).days.ago, 'CAD')
    end

    # Optionally add a one time donation with a different amount, we want to make sure one time donations don't interfere
    create_donation_with_details(20, pledge_frequency_in_days.days.ago, 'USD') if one_time
  end

  def create_donations_with_missing_month(pledge_frequency)
    pledge_frequency_in_days = (pledge_frequency * 30).round
    (1..Contact::StatusSuggester::NUMBER_OF_DONATIONS_TO_SAMPLE).each do |multiplier|
      next if multiplier == 2
      create_donation_with_details(50, (multiplier * pledge_frequency_in_days).days.ago)
    end
  end

  def create_donation_with_details(amount, donation_date, currency = 'USD')
    create(:donation, donor_account: donor_account, designation_account: designation_account,
                      tendered_amount: amount, tendered_currency: currency,
                      amount: amount, currency: currency,
                      donation_date: donation_date)
  end
end
