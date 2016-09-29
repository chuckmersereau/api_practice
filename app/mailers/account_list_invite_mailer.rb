class AccountListInviteMailer < ApplicationMailer
  def email(invite)
    @invite = invite
    mail to: invite.recipient_email, subject: _('Account access invite')
  end
end
