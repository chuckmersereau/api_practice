class Task::Filter::ActivityType < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(activity_type: filters[:activity_type])
  end

  def title
    _('Action')
  end

  def type
    'multiselect'
  end

  def custom_options
    Task::TASK_ACTIVITIES.collect { |activity_type| { name: activity_type, id: activity_type } }
  end
end
