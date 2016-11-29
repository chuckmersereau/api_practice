class Api::V2::AccountLists::InvitesController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_invites
    render json: @invites
  end

  def show
    load_invite
    authorize_invite
    render_invite
  end

  def create
    return show if authorize_and_save_invite
    render json: { success: false, errors: ['Could not send invite'] }, status: 400
  end

  def destroy
    load_invite
    authorize_invite
    @invite.cancel(current_user)
    render_200
  end

  private

  def load_invites
    @invites ||= invite_scope.where(filter_params).to_a
  end

  def load_invite
    @invite ||= AccountListInvite.find(params[:id])
  end

  def render_invite
    render json: @invite
  end

  def authorize_and_save_invite
    authorize AccountListInvite.new(invited_by_user: current_user,
                                    recipient_email: invite_params['recipient_email'],
                                    account_list: load_account_list), :update?
    return false unless EmailValidator.valid?(invite_params['recipient_email'])
    @invite = AccountListInvite.send_invite(current_user, load_account_list, invite_params['recipient_email'])
  end

  def authorize_invite
    authorize @invite
  end

  def invite_params
    params.require(:data).require(:attributes).permit(AccountListInvite::PERMITTED_ATTRIBUTES)
  end

  def invite_scope
    load_account_list.account_list_invites
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permited_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
