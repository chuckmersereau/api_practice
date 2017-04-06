class Contact::Filter::Likely < Contact::Filter::Base
  def execute_query(contacts, filters)
    likely_filters = parse_list(filters[:likely])
    likely_filters << nil if likely_filters.delete('none')
    contacts.where(likely_to_give: likely_filters)
  end

  def title
    _('Likely To Give')
  end

  def parent
    _('Contact Details')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + contact_instance.assignable_likely_to_gives.map { |s| { name: _(s), id: s } }
  end
end
