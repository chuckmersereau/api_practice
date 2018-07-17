class Reports::ActivityResultsPeriod < ActiveModelSerializers::Model
  attr_accessor :account_list, :start_date, :end_date

  ::Task::TASK_ACTIVITIES.each do |activity_type|
    scope = activity_type.parameterize.underscore.to_sym
    ::Activity::REPORT_STATES.each do |state|
      define_method(:"#{state}_#{scope}") do
        activities.send(state.to_sym).where(activity_type: activity_type).count
      end
    end
  end

  def activities
    account_list.activities.where(created_at: (start_date..end_date))
  end
end
