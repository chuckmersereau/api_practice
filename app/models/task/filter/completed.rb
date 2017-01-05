class Task::Filter::Completed < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(completed: filters[:completed])
  end

  def title
    _('Completed')
  end

  def type
    'single_checkbox'
  end

  def default_selection
    nil
  end
end
