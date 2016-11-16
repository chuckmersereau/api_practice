class Api::V2::AccountLists::ImportsController < Api::V2::AccountListsController
  private

  def resource_class
    Import
  end

  def resource_scope
    current_account_list.imports
  end
end
