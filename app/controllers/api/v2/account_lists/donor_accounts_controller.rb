class Api::V2::AccountLists::DonorAccountsController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_donor_accounts
    render json: scoped_donor_accounts, meta: meta_hash(@donor_accounts),
           include: include_params, fields: field_params
  end

  def show
    load_donor_account
    authorize_donor_account
    render_donor_account
  end

  private

  def scoped_donor_accounts
    @donor_accounts.preload(include_associations).map { |donor_account| scoped_donor_account(donor_account) }
  end

  def scoped_donor_account(donor_account)
    ScopedDonorAccount.new(account_list: load_account_list, donor_account: donor_account)
  end

  def load_donor_accounts
    @donor_accounts ||= filter_params[:contacts] ? filtered_donor_accounts : all_donor_accounts
    @donor_accounts = @donor_accounts.where(filter_params_without_contacts)
                                     .reorder(sorting_param)
                                     .page(page_number_param)
                                     .per(per_page_param)
  end

  def load_donor_account
    @donor_account ||= DonorAccount.find_by_uuid_or_raise!(params[:id])
  end

  def render_donor_account
    render json: scoped_donor_account(@donor_account), include: include_params, fields: field_params
  end

  def authorize_donor_account
    authorize @donor_account
  end

  def donor_account_scope
    load_account_list.donor_accounts
  end

  def load_account_list
    @account_list ||= AccountList.find_by_uuid_or_raise!(params[:account_list_id])
  end

  def permitted_filters
    [:contacts]
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end

  def all_donor_accounts
    donor_account_scope
  end

  def filter_params_without_contacts
    filter_params.except(:contacts)
  end

  def filtered_donor_accounts
    donor_account_scope.where(contact_donor_accounts: { contact_id: filter_params[:contacts] })
  end
end
