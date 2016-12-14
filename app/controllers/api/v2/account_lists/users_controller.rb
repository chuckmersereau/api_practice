class Api::V2::AccountLists::UsersController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_users
    render json: @users, meta: meta_hash(@users)
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
    @user.remove_access(load_account_list)
    head :no_content
  end

  def load_users
    @users = user_scope.where(filter_params)
                       .reorder(sorting_param)
                       .page(page_number_param)
                       .per(per_page_param)
  end

  def load_user
    @user ||= User.find_by!(uuid: params[:id])
  end

  def render_user
    render json: @user,
           status: success_status
  end

  def authorize_user
    authorize @user
  end

  def user_scope
    load_account_list.users
  end

  def load_account_list
    @account_list ||= AccountList.find_by!(uuid: params[:account_list_id])
  end

  def permitted_filters
    []
  end

  def pundit_user
    if action_name == 'index'
      PunditContext.new(current_user, account_list: load_account_list)
    else
      current_user
    end
  end
end
