class Task::Filter::Ids < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(activities: { id: parse_list(filters[:ids]) })
  end
end
