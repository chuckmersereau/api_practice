class Contact::Filter::ContactInfoMobile < Contact::Filter::Base
  def execute_query(contacts, filters)
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

  def custom_options
    [{ name: _('Yes'), id: 'Yes' }, { name: _('No'), id: 'No' }]
  end
end
