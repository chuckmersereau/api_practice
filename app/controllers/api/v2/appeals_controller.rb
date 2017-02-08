class Api::V2::AppealsController < Api::V2Controller
  def index
    load_appeals
    render json: @appeals, meta: meta_hash(@appeals), include: include_params, fields: field_params
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
    @appeals = appeal_scope.where(filter_params)
                           .reorder(sorting_param)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def load_appeal
    @appeal ||= Appeal.find_by!(uuid: params[:id])
  end

  def render_appeal
    render json: @appeal,
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
    authorize @appeal
  end

  def permitted_filters
    [:account_list_id]
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
