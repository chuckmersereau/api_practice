class Api::V2::AccountLists::DonorAccountsController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_donor_accounts
    render json: @donor_accounts
  end

  def show
    load_donor_account
    authorize_donor_account
    render_donor_account
  end

  private

  def load_donor_accounts
    @donor_accounts ||= filter_params[:contacts] ? filtered_donor_accounts : all_donor_accounts
  end

  def load_donor_account
    @donor_account ||= DonorAccount.find(params[:id])
  end

  def render_donor_account
    render json: @donor_account
  end

  def authorize_donor_account
    authorize @donor_account
  end

  def donor_account_scope
    load_account_list.donor_accounts
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permited_filters
    [:contacts]
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end

  def all_donor_accounts
    donor_account_scope.to_a
  end

  def filtered_donor_accounts
    donor_account_scope.where(contact_donor_accounts: { contact_id: filter_params[:contacts] }).to_a
  end
end
