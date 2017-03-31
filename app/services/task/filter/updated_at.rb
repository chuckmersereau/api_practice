class Task::Filter::UpdatedAt < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(updated_at: filters[:updated_at])
  end
end
