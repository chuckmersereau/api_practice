class Contact::Filter::RelatedTaskAction < Contact::Filter::Base
  def execute_query(contacts, filters)
    related_task_action_filters = parse_list(filters[:related_task_action])
    if related_task_action_filters.include?('null')
      contacts_with_activities = contacts.where('activities.completed' => false)
                                         .joins(:activities).ids
      contacts.where('contacts.id not in (?)', contacts_with_activities)
    else
      contacts.where('activities.activity_type' => related_task_action_filters)
              .where('activities.completed' => false)
              .joins(:activities)
    end
  end

  def title
    _('Action')
  end

  def parent
    _('Tasks')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + related_tasks.collect { |a| { name: _(a), id: a } }
  end

  private

  def related_tasks
    Task.new.assignable_activity_types & account_lists.collect(&:tasks).flatten.uniq.collect(&:activity_type)
  end
end
