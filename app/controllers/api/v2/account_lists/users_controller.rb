class Api::V2::AccountLists::UsersController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_users
    render json: @users
  end

  def show
    load_user
    authorize_user
    render_user
  end

  def destroy
    load_user
    authorize_user
    @user.remove_access(load_account_list)
    render_200
  end

  private

  def load_users
    @users ||= user_scope.where(filter_params).to_a
  end

  def load_user
    @user ||= User.find(params[:id])
  end

  def render_user
    render json: @user
  end

  def authorize_user
    authorize @user
  end

  def user_scope
    load_account_list.users
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permited_filters
    []
  end

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, load_account_list) : current_user
  end
end
