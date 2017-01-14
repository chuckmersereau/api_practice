class Task
  class AnalyticsSerializer < ::ServiceSerializer
    attributes :last_electronic_newsletter_completed_at,
               :last_physical_newsletter_completed_at,
               :tasks_overdue_or_due_today_counts,
               :total_tasks_due_count
  end
end
