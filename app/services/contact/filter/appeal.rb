class Contact::Filter::Appeal < Contact::Filter::Base
  def execute_query(contacts, filters)
    appeal_filters = parse_list(filters[:appeal])
    contacts = contacts.where(no_appeals: true) if appeal_filters.delete('no_appeals')
    contacts = contacts.joins(:appeals).where(appeals: { id: appeal_filters }).uniq if appeal_filters.present?
    contacts
  end

  def title
    _('Appeal')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('-- Do not ask --'), id: 'no_appeals' }] +
      ::Appeal.select(:name, :id).where(account_list: account_lists).map do |appeal|
        { name: appeal.name, id: appeal.id }
      end
  end
end
