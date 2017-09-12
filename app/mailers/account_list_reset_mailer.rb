class AccountListResetMailer < ApplicationMailer
  layout 'inky'

  def logout(user, reset_log)
    @user = user
    @reset_log = reset_log

    return unless @user.email.present?
    mail to: @user.email.email, subject: _('You must log in to MPDX again')
  end
end
