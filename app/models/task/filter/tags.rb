class Task::Filter::Tags < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.tagged_with(filters[:tags])
  end

  def title
    _('Tags')
  end

  def type
    'multiselect'
  end
end
