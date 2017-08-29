class Contact::Filter::Locale < Contact::Filter::Base
  def execute_query(contacts, filters)
    locale_filters = parse_list(filters[:locale])
    contacts.where('contacts.locale' => locale_filters.map { |l| l == 'null' ? nil : l })
  end

  def title
    _('Language')
  end

  def parent
    _('Contact Details')
  end

  def type
    'multiselect'
  end

  def custom_options
    options = locale_codes.map do |locale_code|
      name_in_english = TwitterCldr::Shared::Languages.from_code_for_locale(locale_code, :en)
      translated_name = name_in_english.present? ? _(name_in_english) : locale_code
      {
        name: translated_name,
        id: locale_code
      }
    end

    default_custom_options + options
  end

  private

  def default_custom_options
    [
      {
        id: 'null',
        name: _('-- Unspecified --')
      }
    ]
  end

  def locale_codes
    (account_lists.flat_map(&:contact_locales) - ['', nil]).uniq.sort
  end
end
