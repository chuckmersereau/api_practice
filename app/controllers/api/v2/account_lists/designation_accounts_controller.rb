class Api::V2::AccountLists::DesignationAccountsController < Api::V2::AccountListsController
  private

  def resource_scope
    current_account_list.designation_accounts
  end

  def resource_class
    DesignationAccount
  end
end
