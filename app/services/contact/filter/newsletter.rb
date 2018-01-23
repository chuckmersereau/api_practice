class Contact::Filter::Newsletter < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts = case filters[:newsletter]
               when 'all'
                 contacts.where.not(send_newsletter: [nil, ''])
               when 'no_value'
                 contacts.where(send_newsletter: [nil, ''])
               when 'none'
                 contacts.where(send_newsletter: 'None')
               when 'address'
                 contacts.where(send_newsletter: %w(Physical Both))
               when 'email'
                 contacts.where(send_newsletter: %w(Email Both))
               when 'address_only'
                 contacts.where(send_newsletter: 'Physical')
               when 'email_only'
                 contacts.where(send_newsletter: 'Email')
               when 'both'
                 contacts.where(send_newsletter: 'Both')
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

  def default_options
    []
  end

  def custom_options
    [{ name: _('Nothing Selected'), id: 'no_value' },
     { name: _('None'), id: 'none' },
     { name: _('All'), id: 'all' },
     { name: _('Physical and Both'), id: 'address' },
     { name: _('Email and Both'), id: 'email' },
     { name: _('Physical Only'), id: 'address_only' },
     { name: _('Email Only'), id: 'email_only' },
     { name: _('Both Only'), id: 'both' }]
  end
end
