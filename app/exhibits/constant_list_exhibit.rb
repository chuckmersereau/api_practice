class ConstantListExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'ConstantList'
  end

  def date_formats_map
    Hash[DATE_FORMATS]
  end

  def languages_map
    Hash[LANGUAGES_CONSTANT]
  end

  def locale_name_map
    locales.each_with_object({}) do |(name, code), hash|
      native_name = TwitterCldr::Shared::Languages.translate_language(name, :en, code)
      hash[code] = {
        native_name: native_name,
        english_name: locale_display_name(name, code)
      }
    end
  end

  def pledge_currencies_code_symbol_map
    Hash[
      codes.map { |code| [code.upcase, currency_information(code.upcase)] }
    ]
  end

  def locale_display_name(name, code)
    format '%s (%s)', name, code
  end

  def bulk_update_options
    {}.tap do |options|
      options['likely_to_give'] = assignable_likely_to_give.dup
      options['status'] = assignable_statuses.dup
      options['send_newsletter'] = assignable_send_newsletter.dup
      options['pledge_received'] = %w(Yes No)
      options['pledge_currency'] = pledge_currencies_code_symbol_map
    end
  end

  def activity_translated_hashes
    translate_array(activities)
  end

  def assignable_likely_to_give_translated_hashes
    translate_array(assignable_likely_to_give)
  end

  def assignable_send_newsletter_translated_hashes
    translate_array(assignable_send_newsletter)
  end

  def status_translated_hashes
    translate_array(statuses)
  end

  def pledge_frequency_translated_hashes
    pledge_frequencies.map do |key, value|
      {
        id: value,
        key: key,
        value: _(value)
      }
    end
  end

  def notification_translated_hashes
    notifications.dup.map do |key, value|
      {
        id: value,
        key: key,
        value: _(value)
      }
    end
  end

  def pledge_frequencies_translated_hashes
    translate_hash(pledge_frequencies)
  end

  def send_appeals_translated_hashes
    translate_hash(send_appeals)
  end

  def assignable_location_translated_hashes
    translate_array(assignable_locations)
  end

  private

  def currency_information(code)
    twitter_cldr_hash = twitter_cldr_currency_information_hash(code)
    {
      code: code,
      code_symbol_string: format('%s (%s)', code, twitter_cldr_hash[:symbol]),
      name: twitter_cldr_hash[:name],
      symbol: twitter_cldr_hash[:symbol]
    }
  end

  def translate_array(array_of_strings)
    array_of_strings.dup.map do |string|
      {
        id: string,
        value: _(string)
      }
    end
  end

  def translate_hash(hash)
    hash.collect do |key, value|
      {
        id: key,
        value: _(value)
      }
    end
  end

  def twitter_cldr_currency_information_hash(code)
    TwitterCldr::Shared::Currencies.for_code(code)
  end
end
