class Task::Filter::Ids < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.where('activities.uuid' => filters[:ids].split(',').map(&:strip))
  end
end
