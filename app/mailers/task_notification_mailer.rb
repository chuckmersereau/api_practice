class TaskNotificationMailer < ApplicationMailer
  layout 'inky'

  def notify(task_id, user_id)
    @task = Task.find_by(id: task_id)
    @user = User.find_by(id: user_id)
    email = @user&.email&.email
    return unless @task && email
    I18n.locale = @user.locale || 'en'
    Time.use_zone(@user.time_zone) do
      mail to: email, subject: _('Task on MPDX')
    end
  end
end
