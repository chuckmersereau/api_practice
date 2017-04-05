class Task::Filter::Completed < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(completed: filters[:completed])
  end
end
