class Api::V2::AccountLists::UsersController < Api::V2::AccountListsController
  def index
    load_resources
    authorize @account_list, :show?
    render json: @resources
  end

  def destroy
    @resource.remove_access(current_account_list)
    render_200
  end

  private

  def resource_class
    User
  end

  def resource_scope
    current_account_list.users
  end

  def pundit_user
    current_user
  end
end
