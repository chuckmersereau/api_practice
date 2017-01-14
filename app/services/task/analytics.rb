class Task::Analytics
  alias read_attribute_for_serialization send

  attr_reader :tasks

  def initialize(tasks)
    @tasks = tasks
  end

  def last_electronic_newsletter_logged
    tasks.completed.newsletter_email.first
  end

  def last_electronic_newsletter_completed_at
    last_electronic_newsletter_logged.try(:completed_at)
  end

  def last_physical_newsletter_logged
    tasks.completed.newsletter_physical.first
  end

  def last_physical_newsletter_completed_at
    last_physical_newsletter_logged.try(:completed_at)
  end

  def tasks_overdue_or_due_today_counts
    Task::TASK_ACTIVITIES.map do |label|
      {
        label: label,
        count: hash_of_task_activities_counts[label] || 0
      }
    end
  end

  def total_tasks_due_count
    tasks.overdue_and_today.count
  end

  private

  def hash_of_task_activities_counts
    @hash_of_task_activities_counts ||= tasks.overdue_and_today
                                             .group(:activity_type)
                                             .count
  end
end
