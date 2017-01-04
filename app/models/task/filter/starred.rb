class Task::Filter::Starred < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(starred: filters[:starred])
  end

  def title
    _('Starred')
  end

  def type
    'checkbox'
  end
end
