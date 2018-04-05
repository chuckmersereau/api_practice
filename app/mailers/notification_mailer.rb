class NotificationMailer < ApplicationMailer
  layout 'inky'

  def notify(user, notifications_by_type, account_list_id = nil)
    @account_list = AccountList.find_by(id: account_list_id) if account_list_id
    @notifications_by_type = notifications_by_type
    @user = user
    email = user&.email&.email
    return unless email
    mail to: email, subject: _('Notifications from MPDX')
  end
end
