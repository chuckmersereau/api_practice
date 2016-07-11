class Api::V1::Preferences::Accounts::UsersController < Api::V1::Preferences::BaseController
  def destroy
    load_user
    authorize
    @user.remove_access(current_account_list)
    render json: { success: true }
  end

  protected

  def authorize
    raise AuthorizationError unless current_user.can_manage_sharing?(current_account_list)
    raise AuthorizationError unless current_user != @user
  end

  def load_user
    @user ||= current_account_list.users.find(params[:id])
  end

  def load_preferences
    @preferences ||= {}
    load_user_preferences
  end

  private

  def load_user_preferences
    @preferences.merge!(
      users: current_account_list.users.map do |user|
        {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email_addresses.first.to_s,
          method: link_method(user),
          deletable: (current_user != user)
        }
      end,
      manager: current_user.can_manage_sharing?(current_account_list)
    )
  end

  def link_method(user)
    designation_profile = current_account_list.designation_profiles.find_by(user: user)
    if designation_profile
      return {
        type: 'designation',
        name: designation_profile.name
      }
    end
    invite = current_account_list.account_list_invites.find_by(accepted_by_user: user)
    if invite
      return {
        type: 'invite',
        inviter: {
          first_name: invite.invited_by_user.first_name,
          last_name: invite.invited_by_user.last_name
        }
      }
    end
    { type: 'mpdx' }
  end
end
