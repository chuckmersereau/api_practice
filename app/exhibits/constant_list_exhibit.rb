class ConstantListExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'ConstantList'
  end

  def bulk_update_options
    {
      'likely_to_give' => translate_array_to_strings(assignable_likely_to_give),
      'send_newsletter' => translate_array_to_strings(assignable_send_newsletter),
      'pledge_currency' => pledge_currencies,
      'pledge_received' => translate_array_to_strings(pledge_received),
      'status' => translate_array_to_strings(assignable_statuses)
    }
  end

  def dates
    Hash[DATE_FORMATS]
  end

  def languages
    Hash[LANGUAGES_CONSTANT]
  end

  def locales
    super.each_with_object({}) do |(name, code), hash|
      native_name = TwitterCldr::Shared::Languages.translate_language(name, :en, code)
      hash[code] = {
        native_name: native_name,
        english_name: format('%s (%s)', name, code)
      }
    end
  end

  def pledge_currencies
    Hash[
      codes.map { |code| [code.upcase, currency_information(code.upcase)] }
    ]
  end

  def pledge_received
    %w(Yes No)
  end

  def activity_hashes
    translate_array(activities)
  end

  def assignable_likely_to_give_hashes
    translate_array(assignable_likely_to_give)
  end

  def assignable_location_hashes
    translate_array(assignable_locations)
  end

  def assignable_send_newsletter_hashes
    translate_array(assignable_send_newsletter)
  end

  def assignable_status_hashes
    translate_array(assignable_statuses)
  end

  def bulk_update_option_hashes
    {
      'likely_to_give' => assignable_likely_to_give_hashes,
      'pledge_currency' => pledge_currency_hashes,
      'pledge_received' => pledge_received_hashes,
      'send_newsletter' => assignable_send_newsletter_hashes,
      'status' => assignable_status_hashes
    }
  end

  def notification_hashes
    translate_hash_with_key(notifications)
  end

  def pledge_currency_hashes
    codes.map do |code|
      currency = currency_information(code.upcase)
      {
        id: currency[:code],
        key: currency[:code],
        value: currency[:code_symbol_string]
      }
    end
  end

  def pledge_frequency_hashes
    translate_hash_with_key(pledge_frequencies)
  end

  def pledge_received_hashes
    translate_array(pledge_received)
  end

  def send_appeals_hashes
    translate_hash(send_appeals)
  end

  def status_hashes
    translate_array(statuses)
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

  def translate_hash_with_key(hash)
    hash.collect do |key, value|
      {
        id: value,
        key: key,
        value: _(value)
      }
    end
  end

  def translate_array_to_strings(array)
    array.dup.map { |string| _(string) }
  end

  def twitter_cldr_currency_information_hash(code)
    TwitterCldr::Shared::Currencies.for_code(code)
  end
end
