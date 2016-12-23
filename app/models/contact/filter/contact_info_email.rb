class Contact::Filter::ContactInfoEmail < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
      contacts_with_emails = contacts.where.not(email_addresses: { email: nil })
                                     .where(email_addresses: { historic: false })
                                     .includes(people: :email_addresses)
      contacts_with_emails_ids = contacts_with_emails.pluck(:id)
      return contacts.where(id: contacts_with_emails_ids) if filters[:contact_info_email] == 'Yes'
      return contacts if contacts_with_emails_ids.empty?
      contacts.where.not(id: contacts_with_emails_ids)
    end

    def title
      _('Email')
    end

    def parent
      _('Contact Information')
    end

    def type
      'radio'
    end

    def custom_options(_account_lists)
      [{ name: _('Yes'), id: 'Yes' }, { name: _('No'), id: 'No' }]
    end
  end
end
