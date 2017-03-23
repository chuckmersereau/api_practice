class Contact::Filter::Church < Contact::Filter::Base
  def execute_query(contacts, filters)
    church_filters = filters[:church].split(',').map(&:strip)
    church_filters << nil if church_filters.delete('none')
    contacts.where(church_name: church_filters)
  end

  def title
    _('Church')
  end

  def parent
    _('Contact Details')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + account_lists.map(&:churches).flatten.uniq.select(&:present?).map { |a| { name: a, id: a } }
  end
end
