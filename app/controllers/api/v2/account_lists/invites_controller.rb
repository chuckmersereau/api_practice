class Api::V2::AccountLists::InvitesController < Api::V2::AccountListsController
  def index
    load_resources
    authorize @account_list, :show?
    render json: @resources
  end

  def create
    return show if authorize_and_send_invite
    render json: { success: false, errors: ['Could not send invite'] }, status: 400
  end

  def destroy
    load_resource
    authorize @resource
    @resource.cancel(current_user)
    render_200
  end

  private

  def authorize_and_send_invite
    authorize AccountListInvite.new(invited_by_user: current_user,
                                    recipient_email: resource_params['recipient_email'],
                                    account_list: current_account_list)
    return false unless EmailValidator.valid?(resource_params['recipient_email'])
    @resource = AccountListInvite.send_invite(current_user, current_account_list, resource_params['recipient_email'])
  end

  def resource_class
    AccountListInvite
  end

  def resource_scope
    current_account_list.account_list_invites
  end
end
