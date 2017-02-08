class Api::V2::AccountLists::InvitesController < Api::V2Controller
  resource_type :account_list_invites

  def index
    authorize load_account_list, :show?
    load_invites
    render json: @invites, meta: meta_hash(@invites), include: include_params, fields: field_params
  end

  def show
    load_invite
    authorize_invite
    render_invite
  end

  def create
    if authorize_and_save_invite
      render_invite
    else
      render json: { success: false, errors: ['Could not send invite'] }, status: 400, include: include_params, fields: field_params
    end
  end

  def destroy
    load_invite
    authorize_invite
    destroy_invite
  end

  private

  def destroy_invite
    @invite.cancel(current_user)
    head :no_content
  end

  def load_invites
    @invites = invite_scope.where(filter_params)
                           .reorder(sorting_param)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def load_invite
    @invite ||= AccountListInvite.find_by!(uuid: params[:id])
  end

  def render_invite
    render json: @invite,
           status: success_status,
           include: include_params,
           fields: field_params
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
    params
      .require(:account_list_invite)
      .permit(AccountListInvite::PERMITTED_ATTRIBUTES)
  end

  def invite_scope
    load_account_list.account_list_invites
  end

  def load_account_list
    @account_list ||= AccountList.find_by!(uuid: params[:account_list_id])
  end

  def permitted_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end

  def transform_uuid_attributes_params_to_ids
    change_specific_param_id_key_to_uuid(params[:data][:attributes], :accepted_by_user_id, User)
    change_specific_param_id_key_to_uuid(params[:data][:attributes], :cancelled_by_user_id, User)
    super
  end
end
