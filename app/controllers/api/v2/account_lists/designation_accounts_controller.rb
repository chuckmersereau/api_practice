class Api::V2::AccountLists::DesignationAccountsController < Api::V2::AccountListsController
  def index
    load_resources
    authorize @account_list, :show?
    render json: @resources
  end

  private

  def resource_scope
    current_account_list.designation_accounts
  end

  def resource_class
    DesignationAccount
  end
end
