class Task::Filter::Starred < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(starred: filters[:starred])
  end

  def title
    _('Starred')
  end

  def type
    'single_checkbox'
  end

  def default_selection
    nil
  end
end
