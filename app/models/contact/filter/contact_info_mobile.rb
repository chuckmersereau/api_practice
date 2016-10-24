class Contact::Filter::ContactInfoMobile < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      filter_mobile = filters[:contact_info_mobile]
      contacts_ids_with_mobile = contact_ids_with_phone(contacts, 'mobile')
      return contacts.where(id: contacts_ids_with_mobile) if filter_mobile == 'Yes'
      contacts.where.not(id: contacts_ids_with_mobile)
    end

    def title
      _('Mobile Phone')
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
