class AccountListInviteMailer < ApplicationMailer
  layout 'inky'

  def email(invite)
    @invite = invite
    @message_values = { inviter: @invite.invited_by_user, account: @invite.account_list.name }
    if invite.invite_user_as == 'coach'
      mail to: invite.recipient_email,
           subject: _('You\'ve been invited to be a coach for an account on MPDX'),
           template_name: 'coach'
    else
      mail to: invite.recipient_email,
           subject: _('You\'ve been invited to access an account on MPDX'),
           template_name: 'user'
    end
  end
end
