class Reports::ActivityResultsPeriodSerializer < ServiceSerializer
  ACTIVITY_TYPE_SCOPES = ::Task::TASK_ACTIVITIES.map do |activity_type|
    scope = activity_type.parameterize.underscore.to_sym
    ::Activity::REPORT_STATES.map { |state| "#{state}_#{scope}".to_sym }
  end.flatten.freeze

  DATE_ATTRIBUTES = [:start_date,
                     :end_date].freeze
  REPORT_ATTRIBUTES = ACTIVITY_TYPE_SCOPES + DATE_ATTRIBUTES
  attributes(*REPORT_ATTRIBUTES)
  delegate(*REPORT_ATTRIBUTES, to: :object)

  def id
    start_date.strftime('%F')
  end
end
