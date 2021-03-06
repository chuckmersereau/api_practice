class Contact::StatusSuggester
  # This constant represents how far back in time we will look to discover a Contact's pledge frequency.
  # For example, a value of a 4 would mean we get the last 4 Donations that the Contact gave, and try
  # to establish if it was 4 years for a annual giver, or 4 months for a monthly giver, etc.
  # A higher value might produce less results, as there might not be enough Donations to sample.
  # This number should not be lower than 4.
  NUMBER_OF_DONATIONS_TO_SAMPLE = 4

  attr_reader :contact, :pledge_frequencies, :donation_scope, :sample_donations,
              :samples_most_frequent_amount

  def initialize(contact:)
    @contact = contact
    @pledge_frequencies = Contact.pledge_frequencies.keys
    @donation_scope = contact.donations.order(donation_date: :desc)
    @sample_donations = donation_scope.limit(NUMBER_OF_DONATIONS_TO_SAMPLE)
    @samples_most_frequent_amount = find_most_frequent_amount_in_sample_donations
  end

  def suggested_pledge_frequency
    return @suggested_pledge_frequency if defined?(@suggested_pledge_frequency)
    @suggested_pledge_frequency = suggested_status == 'Partner - Financial' ? find_suggested_pledge_frequency : nil
  end

  def suggested_pledge_amount
    return @suggested_pledge_amount if defined?(@suggested_pledge_amount)
    @suggested_pledge_amount = suggested_status == 'Partner - Financial' ? samples_most_frequent_amount : nil
  end

  def suggested_pledge_currency
    return @suggested_pledge_currency if defined?(@suggested_pledge_currency)
    @suggested_pledge_currency = suggested_pledge_amount.present? ? find_most_frequent_currency_in_sample_donations : nil
  end

  # We currently only suggest two possible statuses: Partner - Financial, or Partner - Special
  def suggested_status
    if (find_suggested_pledge_frequency.present? && !contact_has_stopped_giving?) || extra_donation_given?
      'Partner - Financial'
    elsif sample_donations.present?
      'Partner - Special'
    end
  end

  def contact_has_stopped_giving?
    return false unless find_suggested_pledge_frequency.present?
    suggested_pledge_frequency_in_days = convert_pledge_frequency_to_days(find_suggested_pledge_frequency)
    sample_donations.present? && donation_scope.where('donation_date > ?', (suggested_pledge_frequency_in_days * 2).days.ago).blank?
  end

  private

  def find_suggested_pledge_frequency
    return nil if donation_scope.blank?
    @found_suggested_pledge_frequency ||= find_pledge_frequency_using_primary_method || find_pledge_frequency_using_secondary_method
  end

  # This method counts the number of times the Contact donated at the given frequency and amount.
  # This approach is intended to catch inconsistent donations, as it doesn't matter when exactly the donation was made,
  # as long as it was sometime within the expected period.
  def find_pledge_frequency_using_primary_method
    find_donations_given_within_a_period
  end

  def extra_donation_given?
    return nil if donation_scope.blank?
    find_donations_given_within_a_period(NUMBER_OF_DONATIONS_TO_SAMPLE + 1)
  end

  def find_donations_given_within_a_period(sample_size = NUMBER_OF_DONATIONS_TO_SAMPLE)
    pledge_frequencies.sort.detect do |pledge_frequency|
      look_back_date = find_look_back_date_for_pledge_frequency(pledge_frequency)
      # Count the number of donations given within the look back period (we also need to consider the current period, which is incomplete)
      donation_scope.where(amount: samples_most_frequent_amount)
                    .where('donation_date >= ?', look_back_date)
                    .count == sample_size
    end
  end

  # This method calculates the number of days in-between the donations,
  # and then finds the most frequently occurring number.
  # This method is useful if there are not very many donations available to analyze (maybe the donor is new).
  def find_pledge_frequency_using_secondary_method
    donations = sample_donations.where(amount: samples_most_frequent_amount)

    # Convert the number days in-between donations into pledge frequencies
    frequencies = number_of_days_in_between_donations(donations).collect do |d|
      convert_number_of_days_to_pledge_frequency(d)
    end

    # Find the most frequently occuring frequency, and return it
    frequencies.uniq.max_by do |frequency_to_look_for|
      frequencies.count { |frequency| frequency == frequency_to_look_for }
    end
  end

  # Based on the given pledge_frequency, find the earliest date after which the donor
  # would hopefully have given the number of donations equal to NUMBER_OF_DONATIONS_TO_SAMPLE.
  def find_look_back_date_for_pledge_frequency(pledge_frequency)
    frequency_in_days = convert_pledge_frequency_to_days(pledge_frequency)

    # The range of time we will look within is based on the most recent donation,
    # this let's us guess the frequency even if they have stopped giving.
    latest_donation_date = donation_scope.first.donation_date
    look_back_date = latest_donation_date - (frequency_in_days * NUMBER_OF_DONATIONS_TO_SAMPLE).round.days

    # Remove half of one period, otherwise periods will start to overlap too much and we'll get worse results.
    look_back_date + (frequency_in_days / 2).round.days
  end

  # Donors that have pledged regular support usually give the same amount each time,
  # but they might give the occasional one-off gift (which is probably of a different amount).
  # We want to exclude the one-off gifts. So, we will find the most frequently given amount,
  # and use that as our guess for the suggested_pledge_amount.
  def find_most_frequent_amount_in_sample_donations
    amounts = sample_donations.pluck(:amount)
    amounts.max_by do |amount_to_look_for|
      amounts.count { |amount| amount == amount_to_look_for }
    end
  end

  # Find the currency that matches our suggested_pledge_amount.
  def find_most_frequent_currency_in_sample_donations
    currencies = sample_donations.where(amount: suggested_pledge_amount).pluck(:currency)
    currencies.max_by do |currency_to_look_for|
      currencies.count { |currency| currency == currency_to_look_for }
    end
  end

  def convert_pledge_frequency_to_days(frequency)
    (frequency * 30).round
  end

  def number_of_days_in_between_donations(donations)
    (0..donations.size - 2).collect do |index|
      ((donations[index].donation_date.to_time - donations[index + 1].donation_date.to_time) / 60 / 60 / 24).round
    end
  end

  # Pledge frequencies are stored relative to month (1.0 frequency is one month).
  # This method will try to convert a number of days to a pledge frequency.
  # For example, 30 days should return 1.0
  # (we need some flexability, because some months have more days than others)
  def convert_number_of_days_to_pledge_frequency(number_of_days)
    pledge_frequencies.sort.detect do |frequency|
      ((27 * frequency).round..(32 * frequency).round).cover?(number_of_days)
    end
  end
end
