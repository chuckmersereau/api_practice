class Constants::ActivityList < ActiveModelSerializers::Model
  def activities
    @activities ||= ::Task::TASK_ACTIVITIES.dup
  end
end
