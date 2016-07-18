class Api::V1::Preferences::Accounts::InvitesController < Api::V1::Preferences::BaseController
  def create
    authorize
    return render json: { success: false }, status: 400 unless save_invite
    render json: { success: true }
  end

  def destroy
    authorize
    load_invite
    @invite.cancel(current_user)
    render json: { success: true }
  end

  protected

  def authorize
    raise AuthorizationError unless current_user.can_manage_sharing?(current_account_list)
  end

  def load_invite
    @invite ||= current_account_list.account_list_invites.find(params[:id])
  end

  def load_preferences
    @preferences ||= {}
    load_invite_preferences
  end

  def save_invite
    return false unless EmailValidator.valid?(invite_params[:email])
    AccountListInvite.send_invite(current_user, current_account_list, invite_params[:email])
  end

  def invite_params
    invite_params = params[:invite]
    return {} unless invite_params
    invite_params.permit(:email)
  end

  private

  def load_invite_preferences
    @preferences.merge!(
      users: current_account_list.account_list_invites.active.where(accepted_by_user: nil).map do |invite|
        {
          id: invite.id,
          email: invite.recipient_email,
          inviter: {
            first_name: invite.invited_by_user.try(:first_name) || '-',
            last_name: invite.invited_by_user.try(:last_name) || '-'
          }
        }
      end,
      manager: current_user.can_manage_sharing?(current_account_list)
    )
  end
end
