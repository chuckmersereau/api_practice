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
    options = locales.map do |locale|
      {
        name: _(locale),
        id: locale
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

  def locales
    account_lists.map(&:contact_locales).flatten.uniq.select(&:present?).sort
  end
end
