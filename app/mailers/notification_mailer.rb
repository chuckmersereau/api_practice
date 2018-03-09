class NotificationMailer < ApplicationMailer
  layout 'inky'

  def notify(user, notifications_by_type)
    @notifications_by_type = notifications_by_type
    @user = user
    email = user&.email&.email
    return unless email
    mail to: email, subject: _('Notifications from MPDX')
  end
end
