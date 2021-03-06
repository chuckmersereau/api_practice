class Contact::Filter::ContactInfoFacebook < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts_with_fb = contacts.where.not(person_facebook_accounts: { username: nil })
                               .joins(people: :facebook_account)
    return contacts_with_fb if filters[:contact_info_facebook] == 'Yes'
    contacts_with_fb_ids = contacts_with_fb.ids
    return contacts if contacts_with_fb_ids.empty?
    contacts.where.not(id: contacts_with_fb_ids)
  end

  def title
    _('Facebook Profile')
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
