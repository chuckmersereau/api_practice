class Api::V2::AccountLists::UsersController < Api::V2::AccountListsController
  def pundit_user
    current_user
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
end
