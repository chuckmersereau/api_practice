module ContactStatusSuggesterSpecHelpers
  def create_donations_to_match_frequency(pledge_frequency, one_time: true)
    pledge_frequency_in_days = (pledge_frequency * 30).round

    # Create consistent donations according to the given pledge_frequency
    (1..Contact::StatusSuggester::NUMBER_OF_DONATIONS_TO_SAMPLE).each do |multiplier|
      create(:donation, donor_account: donor_account, designation_account: designation_account,
                        tendered_amount: 50, tendered_currency: 'CAD',
                        amount: 50, currency: 'CAD',
                        donation_date: (multiplier * pledge_frequency_in_days).days.ago)
    end

    # Optionally add a one time donation with a different amount, we want to make sure one time donations don't interfere
    create(:donation, donor_account: donor_account, designation_account: designation_account,
                      tendered_amount: 20, tendered_currency: 'USD',
                      amount: 20, currency: 'USD',
                      donation_date: pledge_frequency_in_days.days.ago) if one_time
  end
end
