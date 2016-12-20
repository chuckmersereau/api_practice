class Contact::Filter::Church < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      filters[:church] << nil if Array(filters[:church]).delete('none')
      contacts.where('contacts.church_name' => filters[:church])
    end

    def title
      _('Church')
    end

    def parent
      _('Contact Details')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      [{ name: _('-- None --'), id: 'none' }] + account_list.churches.select(&:present?).map { |a| { name: a, id: a } }
    end
  end
end
