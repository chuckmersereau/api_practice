class Contact::Filter::Newsletter < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
      contacts = case filters[:newsletter]
                 when 'all'
                   contacts.where.not(send_newsletter: [nil, ''])
                 when 'none'
                   contacts.where(send_newsletter: [nil, ''])
                 when 'address'
                   contacts.where(send_newsletter: %w(Physical Both))
                 when 'email'
                   contacts.where(send_newsletter: %w(Email Both))
                 when 'both'
                   contacts.where(send_newsletter: %w(Both))
                 else
                   contacts
                 end
      contacts
    end

    def title
      _('Newsletter Recipients')
    end

    def type
      'radio'
    end

    def custom_options(_account_lists)
      [{ name: _('None Selected'), id: 'none' },
       { name: _('All'), id: 'all' },
       { name: _('Physical'), id: 'address' },
       { name: _('Email'), id: 'email' },
       { name: _('Both'), id: 'both' }]
    end
  end
end
