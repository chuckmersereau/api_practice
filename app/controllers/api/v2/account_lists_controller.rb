class Api::V2::AccountListsController < Api::V2Controller
  def index
    load_account_lists
    render_account_lists
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

  def coach?
    if params[:action] == 'show'
      !load_account_list.users.where(id: current_user).exists? &&
        load_account_list.coaches.where(id: current_user).exists?
    else
      false
    end
  end

  def load_account_lists
    @account_lists = account_list_scope.where(filter_params)
                                       .reorder(sorting_param)
                                       .order(default_sort_param)
                                       .page(page_number_param)
                                       .per(per_page_param)
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:id])
  end

  def render_account_list
    options = {
      json:     @account_list,
      status:   success_status,
      include:  include_params,
      fields:   field_params
    }
    options[:serializer] = Coaching::AccountListSerializer if coach?
    render options
  end

  def render_account_lists
    options = {
      json:     @account_lists.preload_valid_associations(include_associations),
      meta:     meta_hash(@account_lists),
      include:  include_params,
      fields:   field_params
    }
    options[:each_serializer] = Coaching::AccountListSerializer if coach?
    render options
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
    if action_name == 'show'
      current_user
    else
      PunditContext.new(current_user, account_list: load_account_list)
    end
  end

  def default_sort_param
    AccountList.arel_table[:created_at].asc
  end
end
