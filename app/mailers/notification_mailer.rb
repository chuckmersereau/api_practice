class NotificationMailer < ApplicationMailer
  layout 'inky'

  def notify(user, notifications_by_type)
    @notifications_by_type = notifications_by_type
    @user = user
    mail to: user.email.email, subject: _('Notifications from MPDX')
  end
end
