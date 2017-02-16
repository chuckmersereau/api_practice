class Task::Filter::Ids < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where('activities.id' => filters[:ids])
  end
end
