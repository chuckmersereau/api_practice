class Api::V2::AccountLists::DesignationAccountsController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_designation_accounts
    render json: @designation_accounts
  end

  def show
    load_designation_account
    authorize_designation_account
    render_designation_account
  end

  private

  def load_designation_accounts
    @designation_accounts ||= designation_account_scope.where(filter_params).to_a
  end

  def load_designation_account
    @designation_account ||= DesignationAccount.find(params[:id])
  end

  def authorize_designation_account
    authorize @designation_account
  end

  def render_designation_account
    render json: @designation_account
  end

  def designation_account_scope
    load_account_list.designation_accounts
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permited_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, load_account_list)
  end
end
