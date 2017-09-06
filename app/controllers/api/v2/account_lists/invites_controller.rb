class Api::V2::AccountLists::InvitesController < Api::V2Controller
  resource_type :account_list_invites
  skip_after_action :verify_authorized, only: :update

  def index
    authorize load_account_list, :show?
    load_invites

    render json: @invites.preload_valid_associations(include_associations),
           meta: meta_hash(@invites),
           include: include_params,
           fields: field_params
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
      render json: { success: false, errors: ['Could not send invite'] },
             status: 400
    end
  end

  def update
    load_account_list_invite
    validate_account_list_invite_code

    if @invite.accept(current_user)
      render_invite
    else
      render json: { success: false, errors: ['No longer valid'] },
             status: 410
    end
  end

  def destroy
    load_invite
    authorize_invite
    destroy_invite
  end

  private

  def validate_account_list_invite_code
    raise Exceptions::BadRequestError, "'data/attributes/code' cannot be blank" if params.dig(:account_list_invite, :code).blank?
    raise Exceptions::BadRequestError, "'data/attributes/code' is invalid" unless valid_invite_code?
  end

  def permitted_filters
    [:invite_user_as]
  end

  def valid_invite_code?
    params.dig(:account_list_invite, :code) == load_account_list_invite.code
  end

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
    @invite ||= AccountListInvite.find_by_uuid_or_raise!(params[:id])
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
                                    invite_user_as: invite_params['invite_user_as'] || 'user',
                                    account_list: load_account_list), :update?
    return false unless EmailValidator.valid?(invite_params['recipient_email'])
    @invite = AccountListInvite.send_invite(current_user, load_account_list, invite_params['recipient_email'], invite_params['invite_user_as'] || 'user')
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
    load_account_list.account_list_invites.active
  end

  def load_account_list
    @account_list ||= AccountList.find_by_uuid_or_raise!(params[:account_list_id])
  end

  def load_account_list_invite
    @invite ||= AccountListInvite.find_by!(uuid: params[:id], account_list: load_account_list)
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
