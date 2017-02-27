class Task::Filter::NoDate < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(no_date: filters[:no_date])
  end

  def title
    _('No Date')
  end

  def type
    'single_checkbox'
  end

  def default_selection
    nil
  end
end