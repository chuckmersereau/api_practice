class Api::V2::AppealsController < Api::V2Controller
  def index
    load_appeals
    render json: @appeals.preload_valid_associations(include_associations),
           scope: { account_list: load_account_list_scope },
           meta: meta_hash(@appeals),
           include: include_params,
           fields: field_params
  end

  def show
    load_appeal
    authorize_appeal
    render_appeal
  end

  def create
    persist_appeal
  end

  def update
    load_appeal
    authorize_appeal
    persist_appeal
  end

  def destroy
    load_appeal
    authorize_appeal
    destroy_appeal
  end

  private

  def destroy_appeal
    @appeal.destroy
    head :no_content
  end

  def load_appeals
    @appeals = appeal_scope.filter(filter_params)
                           .reorder(sorting_param)
                           .order(:created_at)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def load_appeal
    @appeal ||= Appeal.find(params[:id])
  end

  def render_appeal
    render json: @appeal,
           scope: { account_list: load_account_list_scope },
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_appeal
    build_appeal
    authorize_appeal

    if save_appeal
      render_appeal
    else
      render_with_resource_errors(@appeal)
    end
  end

  def build_appeal
    @appeal ||= appeal_scope.build
    @appeal.assign_attributes(appeal_params)
    @appeal.exclusion_filter = params[:appeal][:exclusion_filter]
    @appeal.inclusion_filter = params[:appeal][:inclusion_filter]
  end

  def save_appeal
    @appeal.save(context: persistence_context)
  end

  def appeal_params
    params
      .require(:appeal)
      .permit(Appeal::PERMITTED_ATTRIBUTES)
  end

  def appeal_scope
    Appeal.that_belong_to(current_user)
  end

  def authorize_appeal
    authorize(@appeal)
  end

  def load_account_list_scope
    return unless filter_params[:account_list_id]
    @account_list ||= AccountList.find(filter_params[:account_list_id]).tap do |account_list|
      authorize(account_list, :show?)
    end
  end

  def permitted_filters
    [:account_list_id, :wildcard_search, :appeal_id]
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
