module Types
  TaskAnalyticsType = GraphQL::ObjectType.define do
    name 'TaskAnalytics'
    description "An object of analytics on a User's tasks"

    field :createdAt, !types.String, 'The timestamp of when the analytics were generated', resolve: -> (_,_,_) { Time.current }
    field :lastElectronicNewsletterCompletedAt, types.String, 'Timestamp last electronic newsletter completed', property: :last_electronic_newsletter_completed_at
    field :lastPhysicalNewsletterCompletedAt, types.String, 'Timestamp last physical newsletter completed', property: :last_physical_newsletter_completed_at
    field :tasksOverdueOrDueTodayCounts, types[TaskActivityCountType], 'Array of Counts for overdue tasks', property: :tasks_overdue_or_due_today_counts
    field :totalTasksDueCount, types.Int, 'Total tasks due', property: :total_tasks_due_count
  end
end
