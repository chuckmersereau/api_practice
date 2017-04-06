class Contact::Filter::Appeal < Contact::Filter::Base
  def execute_query(contacts, filters)
    appeal_filters = parse_list(filters[:appeal])
    contacts = contacts.where(no_appeals: true) if appeal_filters.delete('no_appeals')
    contacts = contacts.where(appeals: { uuid: appeal_filters }).includes(:appeals).uniq if appeal_filters.present?
    contacts
  end

  def title
    _('Appeal')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('-- Do not ask --'), id: 'no_appeals' }] + account_lists.map(&:appeals).flatten.uniq.map { |a| { name: a.name, id: a.uuid } }
  end
end
