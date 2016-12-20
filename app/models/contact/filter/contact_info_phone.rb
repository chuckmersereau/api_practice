class Contact::Filter::ContactInfoPhone < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      filter_home = filters[:contact_info_phone]
      contacts_ids_with_home = contact_ids_with_phone(contacts, 'home')
      return contacts.where(id: contacts_ids_with_home) if filter_home == 'Yes'
      contacts.where.not(id: contacts_ids_with_home)
    end

    def title
      _('Home Phone')
    end

    def parent
      _('Contact Information')
    end

    def type
      'radio'
    end

    def custom_options(_account_list)
      [{ name: _('Yes'), id: 'Yes' }, { name: _('No'), id: 'No' }]
    end
  end
end
