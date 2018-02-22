class Api::V2::AccountLists::DonorAccountsController < Api::V2Controller
  serialization_scope :serializer_context

  def index
    authorize load_account_list, :show?
    load_donor_accounts
    render json: @donor_accounts.preload_valid_associations(include_associations),
           meta: meta_hash(@donor_accounts),
           include: include_params,
           fields: field_params
  end

  def show
    load_donor_account
    authorize_donor_account
    render_donor_account
  end

  private

  def load_donor_accounts
    @donor_accounts ||= filter_params[:contacts] ? filtered_donor_accounts : all_donor_accounts
    @donor_accounts = @donor_accounts.filter(load_account_list, filter_params_without_contacts)
                                     .reorder(sorting_param)
                                     .order(:created_at)
                                     .page(page_number_param)
                                     .per(per_page_param)
  end

  def load_donor_account
    @donor_account ||= DonorAccount.find_by!(id: params[:id])
  end

  def render_donor_account
    render json: @donor_account, include: include_params, fields: field_params
  end

  def authorize_donor_account
    authorize @donor_account
  end

  def donor_account_scope
    load_account_list.donor_accounts
  end

  def load_account_list
    @account_list ||= AccountList.find_by!(id: params[:account_list_id])
  end

  def permitted_filters
    [:contacts, :wildcard_search]
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

  def serializer_context
    { account_list: load_account_list, current_user: current_user }
  end
end
