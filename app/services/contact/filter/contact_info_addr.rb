class Contact::Filter::ContactInfoAddr < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts_with_addr = contacts.where.not(addresses: { street: '' })
                                 .where(addresses: { historic: false })
                                 .joins(:addresses)
    contacts_with_addr_ids = contacts_with_addr.ids
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

  def custom_options
    [{ name: _('Yes'), id: 'Yes' },
     { name: _('No'), id: 'No' }]
  end
end
