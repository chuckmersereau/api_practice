class Contact::Filter::Church < Contact::Filter::Base
  def execute_query(contacts, filters)
    filters[:church] << nil if Array(filters[:church]).delete('none')
    contacts.where('contacts.church_name' => filters[:church])
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
