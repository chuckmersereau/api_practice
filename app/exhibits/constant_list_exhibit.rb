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
      codes.map { |c| [c, currency_code_and_symbol(c)] }
    ]
  end

  def currency_code_and_symbol(code)
    format '%s (%s)', code, currency_symbol(code)
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
      options['locale'] = mail_chimp_locale_options.dup
    end
  end

  def activities_translated
    translate_array(activities)
  end

  def assignable_likely_to_give_translated
    translate_array(assignable_likely_to_give)
  end

  def assignable_send_newsletter_translated
    translate_array(assignable_send_newsletter)
  end

  def statuses_translated
    translate_array(statuses)
  end

  def notifications_translated
    notifications.dup.tap do |n|
      n.keys.each { |key| n[key] = _(n[key]) }
    end
  end

  private

  def translate_array(array)
    array.map { |element| _(element) }
  end
end
