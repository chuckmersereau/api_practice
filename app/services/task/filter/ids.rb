class Task::Filter::Ids < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where(activities: { uuid: parse_list(filters[:ids]) })
  end
end
