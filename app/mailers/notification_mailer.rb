class NotificationMailer < ApplicationMailer
  def notify(account_list, notifications_by_type)
    @notifications_by_type = notifications_by_type

    mail to: account_list.users.map(&:email).compact.map(&:email),
         subject: _('Notifications from MPDX')
  end
end
