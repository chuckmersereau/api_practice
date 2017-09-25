class Contact::Filter::TasksAllCompleted < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts = contacts.where.not(id: contacts_with_incomplete_tasks(contacts)) if filters[:tasks_all_completed]&.to_s == 'true'
    contacts
  end

  def contacts_with_incomplete_tasks(contacts)
    contacts.joins(:activities).where(activities: { completed: false })
  end

  def title
    _('No Incomplete Tasks')
  end

  def parent
    _('Tasks')
  end

  def type
    'single_checkbox'
  end

  def empty?
    false
  end

  def default_selection
    false
  end
end
