class Api::V2::AccountListsController < Api::V2::ResourceController
  def pundit_user
    CurrentContext.new(current_user, current_account_list)
  end

  protected

  def resource_class
    AccountList
  end

  def resource_scope
    account_list_scope
  end

  def current_account_list
    @account_list ||= AccountList.find(relevant_account_list_id)
  end

  private

  def account_list_scope
    current_user.account_lists
  end

  def relevant_account_list_id
    params[:account_list_id] ? params[:account_list_id] : params[:id]
  end
end
