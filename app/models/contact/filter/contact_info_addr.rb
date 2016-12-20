class Contact::Filter::ContactInfoAddr < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      contacts_with_addr = contacts.where.not(addresses: { street: '' })
                                   .where(addresses: { historic: false })
                                   .includes(:addresses)
      contacts_with_addr_ids = contacts_with_addr.pluck(:id)
      return contacts.where(id: contacts_with_addr_ids) if filters[:contact_info_addr] == 'Yes'
      return contacts if contacts_with_addr_ids.empty?
      contacts.where.not(id: contacts_with_addr_ids)
    end

    def title
      _('Address')
    end

    def parent
      _('Contact Information')
    end

    def type
      'radio'
    end

    def custom_options(_account_list)
      [{ name: _('Yes'), id: 'Yes' },
       { name: _('No'), id: 'No' }]
    end
  end
end
