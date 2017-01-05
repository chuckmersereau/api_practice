class Task::Filter::ContactIds < Task::Filter::Base
  def execute_query(tasks, filters)
    filters[:contact_ids] = filters[:contact_ids].split(',') if filters[:contact_ids].is_a?(String)
    tasks.includes(:contacts).references(:contacts).where(contacts: { uuid: filters[:contact_ids] })
  end

  def title
    _('Contacts')
  end

  def type
    'multiselect'
  end

  def custom_options
    account_lists.collect(&:contacts).flatten.uniq.collect { |contact| { name: contact.to_s, id: contact.uuid } }
  end
end
