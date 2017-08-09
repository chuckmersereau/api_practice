require 'async'

class TaskNotificationsWorker
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :api_task_notifications_worker, unique: :until_executed

  def perform
    tasks = Task.where(start_at: Time.now..65.minutes.from_now, notification_scheduled: nil)
                .where.not(notification_time_before: nil)
    tasks.find_each do |task|
      task.account_list.users.each do |user|
        TaskNotificationMailer.delay_until(
          task.start_at - task.notification_time_before.send(task.notification_time_unit)
        ).notify(task.id, user.id)
      end
    end
    tasks.update_all(notification_scheduled: true)
  end
end
