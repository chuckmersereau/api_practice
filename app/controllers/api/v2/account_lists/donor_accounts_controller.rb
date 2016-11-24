class Api::V2::AccountLists::DonorAccountsController < Api::V2::AccountListsController
  def index
    load_resources
    authorize @account_list, :show?
    render json: @resources
  end

  private

  def resource_scope
    current_account_list.donor_accounts
  end

  def resource_class
    DonorAccount
  end
end
