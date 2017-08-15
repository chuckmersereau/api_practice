class TaskNotificationMailer < ApplicationMailer
  layout 'inky'

  def notify(task_id, user_id)
    @task = Task.find_by(id: task_id)
    @user = User.find_by(id: user_id)
    Time.use_zone(@user.time_zone) do
      mail to: @user.email.try(:email),
           subject: _('Task on MPDX') if @task && @user
    end
  end
end
