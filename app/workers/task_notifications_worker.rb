require 'async'

class TaskNotificationsWorker
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :api_task_notifications_worker, unique: :until_executed

  def perform
    tasks_ready_for_notification.find_each do |task|
      send_notification_to_all_account_users(task)
      task.update_column(:notification_scheduled, true)
    end
  end

  def tasks_ready_for_notification
    Task.unscheduled
        .starting_between(::Time.current..24.hours.from_now)
        .with_notification_time
        .notify_by([Task.notification_types[:email], Task.notification_types[:both]])
  end

  def send_notification_to_all_account_users(task)
    delayed_until = determine_start_time(task)
    task.account_list.users.each { |user| send_notification(task.id, user.id, delayed_until) }
  end

  def determine_start_time(task)
    time_unit = task.notification_time_unit || 'minutes'
    task.start_at - task.notification_time_before.send(time_unit)
  end

  def send_notification(task_id, user_id, delayed_until)
    TaskNotificationMailer.delay_until(delayed_until).notify(task_id, user_id)
  end
end
