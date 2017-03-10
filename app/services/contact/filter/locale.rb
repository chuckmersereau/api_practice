class Contact::Filter::Locale < Contact::Filter::Base
  def execute_query(contacts, filters)
    locale_filters = filters[:locale].split(',').map(&:strip)
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
    [{ name: _('-- Unspecified --'), id: 'null' }] +
      account_lists.map(&:contact_locales).flatten.uniq.select(&:present?).map do |locale|
        { name: _(MailChimpAccount::Locales::LOCALE_NAMES[locale]), id: locale }
      end
  end
end
