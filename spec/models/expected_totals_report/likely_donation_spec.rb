require 'spec_helper'

describe ExpectedTotalsReport::LikelyDonation, '#likely_more' do
  it 'gives zero if pledge not received' do
    contact = build_stubbed(:contact, pledge_received: false,
                                      status: 'Partner - Financial')

    expect_zero_amount(contact)
  end

  it 'gives zero if not financial partner' do
    contact = build_stubbed(:contact, pledge_received: false,
                                      status: 'Partner - Special')

    expect_zero_amount(contact)
  end

  it 'gives zero if there is no commitment amount' do
    contact = build_stubbed(:contact, pledge_received: true,
                                      status: 'Partner - Financial', pledge_amount: nil)

    expect_zero_amount(contact)
  end

  it 'gives zero if pledge_frequency is nil' do
    contact = build_stubbed(:contact, pledge_received: true,
                                      status: 'Partner - Financial', pledge_amount: 5,
                                      pledge_frequency: nil)

    expect_zero_amount(contact)
  end

  def expect_zero_amount(contact)
    expect(ExpectedTotalsReport::LikelyDonation
      .new(contact: contact, recent_donations: [], date_in_month: Date.new(2016, 1, 1))
      .likely_more)
      .to eq 0.0
  end

  # These are for a financial partner with a pledge amount of 5.
  MONTH_BASED_TEST_CASES = [
    # Expect zero if no donations given yet
    { pledge_frequency: 1, recent_donations: [], likely_more: 0 },

    # Expect full commitment if started giving and no missed months (first zero
    # is for current month).
    { pledge_frequency: 1, recent_donations: [0, 5], likely_more: 5 },
    { pledge_frequency: 1, recent_donations: [0, 5, 5, 5], likely_more: 5 },

    # Expect 0 if partner already gave this month.
    { pledge_frequency: 1, recent_donations: [5], likely_more: 0 },

    # Partner started, has been consistent last 3+ months, but only gave
    # partial amount this month. Most likely they give twice per month. I have a
    # ministry partner like that who gives $50/mo from both husband and wife at
    # slightly different times of the month.
    { pledge_frequency: 1, recent_donations: [3, 5, 5, 5], likely_more: 2 },

    # Partner started, has not been consistent for 3+ months, and only gave
    # partial amount. Most likely they are kind of flaky and they may not be
    # willing to follow through on their commitment.
    { pledge_frequency: 1, recent_donations: [3, 5, 5], likely_more: 0 },

    # Partner has not been consistent the past 3 months even though they gave
    # full amount previous month. Assume they are flaky and won't give.
    { pledge_frequency: 1, recent_donations: [0, 5, 0, 5], likely_more: 0 },

    # Partner has averaged out to consistent over the past 3 months even though
    # they have missed a specific month in the past 3. They have given at
    # least something in at least 2 of the 3 last months. Expect they will give.
    { pledge_frequency: 1, recent_donations: [0, 0, 10, 5], likely_more: 5 },

    # Partner has averaged out to consistent over the past 3 months, but they
    # have missed 2 of the last 3 months. Assume they won't give this month
    # because they seem to be more of a sporatic giver.
    { pledge_frequency: 1, recent_donations: [0, 0, 0, 15], likely_more: 0 },

    # Partner has not averaged out to consistent over the past 3 months and they
    # have also missed last month. Assume they are not going to give this month.
    { pledge_frequency: 1, recent_donations: [0, 0, 5, 5], likely_more: 0 },

    # Partner has been giving less than their commitment. Assume they are
    # giving special gifts but are not keeping up with their commitment.
    # This could motivate the user to contact the partner and correct the amount.
    { pledge_frequency: 1, recent_donations: [0, 4, 4, 4], likely_more: 0 },

    # Partner has been consistent on average but only occasionally gives (less
    # than 2 of past 3 months have any gifts) even though their specified
    # commitment frequency is monthly. Assume they give when they feel like
    # it to randomly making up missed months and to be conservative assume they
    # won't choose this month to make it up.
    { pledge_frequency: 1, recent_donations: [0, 0, 0, 15], likely_more: 0 },

    # Partner has been giving more than their commitment, but only assume they
    # will give their commitment this month.
    { pledge_frequency: 1, recent_donations: [0, 8, 6, 7], likely_more: 5 },

    # Partner started giving and this is their month to give because they gave
    # two months ago.
    { pledge_frequency: 2, recent_donations: [0, 0, 5], likely_more: 5 },

    # Partner has started giving but this is not their month to give because
    # they gave last month.
    { pledge_frequency: 2, recent_donations: [0, 5], likely_more: 0 },

    # Partner has been somewhat inconsistent in which month they give,
    # but they gave two months ago (and are bi-monthly), so assume they will
    # give this month.
    { pledge_frequency: 2, recent_donations: [0, 0, 5, 5, 0, 0, 5, 0, 5],
      likely_more: 5 },

    # Annual partner gave this month last year, but has only given once.
    # Assume they won't give this month - subtly prompting the user to follow
    # up with them (they should have gotten the "expected gift in a month"
    # notice if they had that setting turned on). Last gift did not have the
    # channel of "Recurring"
    { pledge_frequency: 12, recent_donations: Array.new(12, 0) + [5],
      channel: 'Mail', likely_more: 0 },

    # Annual partner gave only once on this month last year but gift channel
    # was "Recurring". Assume they will give.
    { pledge_frequency: 12, recent_donations: Array.new(12, 0) + [5],
      channel: 'Recurring', likely_more: 5 },

    # Annual partner gave this month last year and the same month the year
    # before. Assume they will give this month.
    { pledge_frequency: 12,
      recent_donations: Array.new(12, 0) + [5] + Array.new(11, 0) + [5],
      channel: 'Mail', likely_more: 5 },

    # Partner is set as Annual but they have been making up their annual
    # commitment by giving at random increments throughout the year.
    # Assume they won't give this month.
    { pledge_frequency: 12,
      recent_donations: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 3] +
        Array.new(11, 0) + [5],
      channel: 'Mail', likely_more: 0 },

    # Partner is set to Annual, has given for the past two years but last year
    # gave less than their commitment. Assume won't give this month.
    { pledge_frequency: 12,
      recent_donations: Array.new(12, 0) + [4] + Array.new(11, 0) + [5],
      channel: 'Mail', likely_more: 0 },

    # Annual partner is up to date in their giving, but occasionally gives
    # special gifts, that's OK, that shouldn't confuse the system to think
    # they are inconsistent. (Assuming they gave the past 2 years on the same
    # month).
    { pledge_frequency: 12,
      recent_donations: [0, 0, 0, 2, 0, 0, 1, 1, 0, 0, 0, 0, 5] +
        Array.new(11, 0) + [5],
      channel: 'Mail', likely_more: 5 }

  ].freeze

  it 'examines recent donation history and guesses expected gift amounts' do
    contact = build_stubbed(:contact, pledge_received: true,
                                      status: 'Partner - Financial', pledge_amount: 5)
    MONTH_BASED_TEST_CASES.each do |test_case|
      expect_correct_amount(contact, test_case)
    end
  end

  def expect_correct_amount(contact, test_case)
    contact.pledge_frequency = test_case[:pledge_frequency]

    donations = []
    test_case[:recent_donations].each_with_index do |amount, index|
      next if amount.zero?
      date = Date.current << index
      donations << build_stubbed(:donation, tendered_amount: amount,
                                            donation_date: date,
                                            channel: test_case[:channel])
    end
    update_donation_dates(contact, donations)

    actual_amount = ExpectedTotalsReport::LikelyDonation
                    .new(contact: contact, recent_donations: donations, date_in_month: Date.current)
                    .likely_more
    return if actual_amount == test_case[:likely_more]

    message = "Expected #{test_case[:likely_more]} but got #{actual_amount} "\
        "for case #{test_case.inspect}"
    expect(actual_amount).to eq(test_case[:likely_more]), message
  end

  describe 'for weekly donors' do
    let(:weekly) { Contact.pledge_frequencies.invert['Weekly'] }
    let(:contact) do
      build_stubbed(:contact, pledge_amount: 5, pledge_frequency: weekly,
                              pledge_received: true)
    end

    it 'gives zero if fewer than two weeks worth of gifts in past 17 days' do
      donations = [
        build_stubbed(:donation, amount: 5, donation_date: Date.new(2016, 4, 20))
      ]
      update_donation_dates(contact, donations)

      expect(ExpectedTotalsReport::LikelyDonation
        .new(contact: contact, recent_donations: donations,
             date_in_month: Date.new(2016, 4, 29)).likely_more)
        .to eq 0.0
    end

    it 'gives pledge times full weeks remaining in month if recently consistent' do
      donations = [
        build_stubbed(:donation, amount: 5, donation_date: Date.new(2016, 4, 3)),
        build_stubbed(:donation, amount: 5, donation_date: Date.new(2016, 4, 10))
      ]
      update_donation_dates(contact, donations)

      expect(ExpectedTotalsReport::LikelyDonation
        .new(contact: contact, recent_donations: donations,
             date_in_month: Date.new(2016, 4, 13)).likely_more)
        .to eq 10
    end
  end

  describe 'for fortnightly donors' do
    let(:fortnightly) { Contact.pledge_frequencies.invert['Every 2 Weeks'] }
    let(:contact) do
      build_stubbed(:contact, pledge_amount: 5, pledge_received: true,
                              pledge_frequency: fortnightly)
    end

    it 'gives zero if fewer than two gifts worth received in past 31 days' do
      donations = [
        build_stubbed(:donation, amount: 5, donation_date: Date.new(2016, 4, 20))
      ]
      update_donation_dates(contact, donations)

      expect(ExpectedTotalsReport::LikelyDonation
        .new(contact: contact, recent_donations: donations,
             date_in_month: Date.new(2016, 4, 29)).likely_more)
        .to eq 0.0
    end

    it 'gives pledge times full 14 day periods remaining in month' do
      donations = [
        build_stubbed(:donation, amount: 5, donation_date: Date.new(2016, 3, 27)),
        build_stubbed(:donation, amount: 5, donation_date: Date.new(2016, 4, 10))
      ]
      update_donation_dates(contact, donations)

      expect(ExpectedTotalsReport::LikelyDonation
        .new(contact: contact, recent_donations: donations,
             date_in_month: Date.new(2016, 4, 10)).likely_more)
        .to eq 5
    end
  end

  def update_donation_dates(contact, donations)
    contact.first_donation_date = donations.map(&:donation_date).min
    contact.last_donation_date = donations.map(&:donation_date).max
  end
end
