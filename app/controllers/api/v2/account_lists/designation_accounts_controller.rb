class Api::V2::AccountLists::DesignationAccountsController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_designation_accounts
    render json: @designation_accounts.preload_valid_associations(include_associations),
           meta: meta_hash(@designation_accounts),
           include: include_params,
           fields: field_params
  end

  def show
    load_designation_account
    authorize_designation_account
    render_designation_account
  end

  def update
    load_designation_account
    authorize_designation_account
    persist_designation_account
  end

  private

  def load_designation_accounts
    @designation_accounts = designation_account_scope.filter(filter_params)
                                                     .reorder(sorting_param)
                                                     .order(default_sort_param)
                                                     .page(page_number_param)
                                                     .per(per_page_param)
  end

  def load_designation_account
    @designation_account ||= DesignationAccount.find(params[:id])
  end

  def authorize_designation_account
    authorize @designation_account
  end

  def render_designation_account
    render json: @designation_account, include: include_params, fields: field_params
  end

  def persist_designation_account
    build_designation_account
    authorize_designation_account

    if save_designation_account
      render_designation_account
    else
      render_with_resource_errors(@designation_account)
    end
  end

  def build_designation_account
    @designation_account.assign_attributes(designation_account_params)
  end

  def save_designation_account
    @designation_account.save(context: persistence_context)
  end

  def designation_account_params
    params
      .require(:designation_account)
      .permit(DesignationAccount::PERMITTED_ATTRIBUTES)
  end

  def designation_account_scope
    load_account_list.designation_accounts
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permitted_filters
    [:wildcard_search]
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end

  def default_sort_param
    DesignationAccount.arel_table[:created_at].asc
  end
end
