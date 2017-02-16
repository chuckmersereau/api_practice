class Contact::Filter::Status < Contact::Filter::Base
  def execute_query(contacts, filters)
    filters[:status] = Array(filters[:status])
    filters[:status] << 'null' if (filters[:status].include? '') && !filters[:status].include?('null')
    filters[:status] << '' if (filters[:status].include? 'null') && !filters[:status].include?('')
    filters[:status] += Contact.active_statuses if filters[:status].include?('active')
    filters[:status] += Contact.inactive_statuses if filters[:status].include?('hidden')
    if filters[:status].include? 'null'
      return contacts.where('status is null OR status in (?)', filters[:status])
    end
    contacts.where(status: filters[:status])
  end

  def title
    _('Status')
  end

  def type
    'multiselect'
  end

  def default_options
    []
  end

  def default_selection
    %w(active null)
  end

  def custom_options
    [{ name: _('-- All Active --'), id: 'active' },
     { name: _('-- All Hidden --'), id: 'hidden' },
     { name: _('-- None --'), id: 'null' }] +
      contact_instance.assignable_statuses.map { |s| { name: _(s), id: s } }
  end
end
