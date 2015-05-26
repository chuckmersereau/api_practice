class NotificationType::CallPartnerOncePerYear < NotificationType::TaskIfPeriodPast
  def task_description_template
    '%{contact_name} have not had an attempted call logged in the past year. Call them.'
  end

  def task_activity_type
    'Call'
  end
end
