class AccountListInviteMailer < ApplicationMailer
  helper :account_list_invites

  def email(invite)
    @invite = invite
    mail to: invite.recipient_email, subject: _('Account access invite')
  end
end
