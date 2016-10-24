class Api::V1::DesignationAccountsController < Api::V1::BaseController
  def index
    load_designation_accounts
    render json: @designation_accounts, callback: params[:callback]
  end

  protected

  def load_designation_accounts
    @designation_accounts ||= designation_accounts_scope.all
  end

  def designation_accounts_scope
    current_account_list.designation_accounts
  end
end
