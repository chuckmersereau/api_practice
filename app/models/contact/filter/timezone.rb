class Contact::Filter::Timezone < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      contacts.where('contacts.timezone' => filters[:timezone])
    end

    def title
      _('Timezone')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      account_list.timezones.select(&:present?).map { |a| { name: a, id: a } }
    end
  end
end
