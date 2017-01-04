class Contact::Filter::ContactType < Contact::Filter::Base
  def execute_query(contacts, filters)
    case filters[:contact_type]
    when 'person'
      contacts.people
    when 'company'
      contacts.companies
    end
  end

  def title
    _('Type')
  end

  def parent
    _('Contact Details')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('Person'), id: 'person' }, { name: _('Company'), id: 'company' }]
  end
end
