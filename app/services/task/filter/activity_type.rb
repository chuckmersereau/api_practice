class Task::Filter::ActivityType < Task::Filter::Base
  def execute_query(tasks, filters)
    parsed_filters = parse_list(filters[:activity_type])

    if parsed_filters.include?('none')
      parsed_filters.delete('none')
      parsed_filters << ''
      return tasks.where('activity_type IS NULL OR activity_type in (?)', parsed_filters)
    end

    tasks.where(activity_type: parsed_filters)
  end

  def title
    _('Action')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] +
      Task::TASK_ACTIVITIES.collect { |activity_type| { name: _(activity_type), id: activity_type } }
  end
end
