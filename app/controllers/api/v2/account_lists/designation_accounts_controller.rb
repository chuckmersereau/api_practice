class Api::V2::AccountLists::DesignationAccountsController < Api::V2::AccountListsController
  def resource_scope
    current_account_list.designation_accounts
  end
end
