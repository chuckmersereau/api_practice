class Contact::Filter::Status < Contact::Filter::Base
  def execute_query(contacts, filters)
    status_filters = parse_list(filters[:status])
    status_filters << 'null' if (status_filters.include? '') && !status_filters.include?('null')
    status_filters << '' if (status_filters.include? 'null') && !status_filters.include?('')
    status_filters += Contact.active_statuses + ['null'] if status_filters.include?('active')
    status_filters += Contact.inactive_statuses if status_filters.include?('hidden')

    if status_filters.include? 'null'
      return contacts.where('status is null OR status in (?)', status_filters)
    end
    contacts.where(status: status_filters)
  end

  def execute_reverse_query(contacts, filters)
    status_filters = parse_list(filters[:status])

    if (%w(active null) & status_filters).any?
      status_filters -= %w(active null)
      status_filters << 'hidden'
    elsif status_filters.delete('hidden')
      status_filters << 'null'
    else
      return nil
    end

    filters[:status] = status_filters.join(',')
    execute_query(contacts, filters)
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
    'active, null'
  end

  def custom_options
    [{ name: _('-- All Active --'), id: 'active' },
     { name: _('-- All Hidden --'), id: 'hidden' },
     { name: _('-- None --'), id: 'null' }] +
      contact_instance.assignable_statuses.map { |state| { name: _(state), id: state } }
  end
end
