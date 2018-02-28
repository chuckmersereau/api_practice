class Api::V2::Coaching::AccountListsController < Api::V2Controller
  resource_type :account_lists

  def index
    load_account_lists
    render json: @account_lists.preload_valid_associations(include_associations),
           meta: meta_hash(@account_lists),
           include: include_params,
           fields: field_params,
           each_serializer: Coaching::AccountListSerializer
  end

  def show
    load_account_list
    authorize_account_list
    render_account_list
  end

  private

  def load_account_lists
    @account_lists = account_lists_scope.where(filter_params)
                                        .reorder(sorting_param)
                                        .order(:created_at)
                                        .page(page_number_param)
                                        .per(per_page_param)
  end

  def account_lists_scope
    current_user.becomes(User::Coach).coaching_account_lists
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:id])
  end

  def authorize_account_list
    authorize @account_list
  end

  def render_account_list
    render json: @account_list,
           status: success_status,
           include: include_params,
           fields: field_params,
           serializer: Coaching::AccountListSerializer
  end

  def permitted_sorting_params
    %w(name active_mpd_start_at active_mpd_finish_at)
  end
end
