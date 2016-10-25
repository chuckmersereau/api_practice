class Contact::Filter::Locale < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      contacts.where('contacts.locale' => filters[:locale].map { |l| l == 'null' ? nil : l })
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

    def custom_options(account_list)
      [{ name: _('-- Unspecified --'), id: 'null' }] +
        account_list.contact_locales.select(&:present?).map do |locale|
          { name: _(MailChimpAccount::Locales::LOCALE_NAMES[locale]), id: locale }
        end
    end
  end
end
