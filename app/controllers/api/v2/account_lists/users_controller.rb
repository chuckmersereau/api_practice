class Api::V2::AccountLists::UsersController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_users
    render json: @users.preload_valid_associations(include_associations),
           meta: meta_hash(@users),
           include: include_params,
           fields: field_params,
           each_serializer: AccountListUserSerializer
  end

  def show
    load_user
    authorize_user
    render_user
  end

  def destroy
    load_user
    authorize_user
    destroy_user
  end

  private

  def destroy_user
    @user.remove_user_access(load_account_list)
    head :no_content
  end

  def load_users
    @users = user_scope.where(filter_params)
                       .reorder(sorting_param)
                       .page(page_number_param)
                       .per(per_page_param)
  end

  def load_user
    @user ||= User.find_by_uuid_or_raise!(params[:id])
  end

  def render_user
    render json: @user,
           status: success_status,
           include: include_params,
           fields: field_params,
           serializer: AccountListUserSerializer
  end

  def authorize_user
    authorize @user
  end

  def user_scope
    load_account_list.users
  end

  def load_account_list
    @account_list ||= AccountList.find_by_uuid_or_raise!(params[:account_list_id])
  end

  def pundit_user
    if action_name == 'index'
      PunditContext.new(current_user, account_list: load_account_list)
    else
      current_user
    end
  end
end
