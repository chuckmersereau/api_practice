class Contact::Filter::RelatedTaskAction < Contact::Filter::Base
  def execute_query(contacts, filters)
    related_task_action_filters = parse_list(filters[:related_task_action])
    if includes_none?(related_task_action_filters)
      contacts_with_tasks = contacts.joins(:activities)
                                    .where('activities.completed' => false,
                                           'activities.type' => Task.sti_name)
                                    .ids
      contacts.where('contacts.id not in (?)', contacts_with_tasks)
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

  def includes_none?(filter_list)
    filter_list.include?('none') || filter_list.include?('null')
  end

  def related_tasks
    Task.new.assignable_activity_types & Task.where(account_list: account_lists).distinct.pluck(:activity_type)
  end
end
