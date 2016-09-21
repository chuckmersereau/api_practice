class TaskNotificationMailer < ActionMailer::Base
  default from: 'support@mpdx.org'

  def notify(task)
    @task = task
    mail to: task.account_list.users.map(&:email).compact.map(&:email),
         subject: _('Task on MPDX')
  end
end
