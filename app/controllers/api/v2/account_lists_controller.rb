class Api::V2::AccountListsController < Api::V2Controller
  def index
    load_account_lists
    render json: @account_lists.preload_valid_associations(include_associations),
           meta: meta_hash(@account_lists),
           include: include_params,
           fields: field_params
  end

  def show
    load_account_list
    authorize_account_list
    render_account_list
  end

  def update
    load_account_list
    authorize_account_list
    persist_account_list
  end

  private

  def load_account_lists
    @account_lists = account_list_scope.where(filter_params)
                                       .reorder(sorting_param)
                                       .order(:created_at)
                                       .page(page_number_param)
                                       .per(per_page_param)
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:id])
  end

  def render_account_list
    render json: @account_list,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_account_list
    build_account_list
    authorize_account_list

    if save_account_list
      render_account_list
    else
      render_with_resource_errors(@account_list)
    end
  end

  def build_account_list
    @account_list ||= account_list_scope.build
    @account_list.assign_attributes(account_list_params)
  end

  def save_account_list
    @account_list.save(context: persistence_context)
  end

  def account_list_params
    params
      .require(:account_list)
      .permit(AccountList::PERMITTED_ATTRIBUTES)
  end

  def account_list_scope
    current_user.account_lists
  end

  def authorize_account_list
    authorize @account_list
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
