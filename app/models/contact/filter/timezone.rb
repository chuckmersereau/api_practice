class Contact::Filter::Timezone < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
      contacts.where('contacts.timezone' => filters[:timezone])
    end

    def title
      _('Timezone')
    end

    def type
      'multiselect'
    end

    def custom_options(account_lists)
      account_lists.map(&:timezones).flatten.uniq.select(&:present?).map { |a| { name: a, id: a } }
    end
  end
end
