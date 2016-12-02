class Api::V2::AppealsController < Api::V2Controller
  def index
    load_appeals
    render json: @appeals, meta: meta_hash(@appeals)
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
    @appeal.destroy
    render_200
  end

  private

  def load_appeals
    @appeals = appeal_scope.where(filter_params)
                           .reorder(sorting_param)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def load_appeal
    @appeal ||= Appeal.find(params[:id])
  end

  def render_appeal
    render json: @appeal
  end

  def persist_appeal
    build_appeal
    authorize_appeal
    return show if save_appeal
    render_400_with_errors(@appeal)
  end

  def build_appeal
    @appeal ||= appeal_scope.build
    @appeal.assign_attributes(appeal_params)
  end

  def save_appeal
    @appeal.save
  end

  def appeal_params
    params.require(:data).require(:attributes).permit(Appeal::PERMITTED_ATTRIBUTES)
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
