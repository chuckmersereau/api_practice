class Api::V2::AccountLists::DonorAccountsController < Api::V2::AccountListsController
  private

  def resource_scope
    current_account_list.donor_accounts
  end

  def resource_class
    DonorAccount
  end
end
