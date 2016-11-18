class Api::V2::AppealsController < Api::V2::ResourceController
  skip_before_action :load_resource, :authorize_resource

  def index
    load_appeals
    render json: @resources
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
    @resource.destroy
    render_200
  end

  private

  def load_appeals
    @resources ||= appeal_scope.to_a
  end

  def load_appeal
    @resource ||= appeal_scope.find(params[:id])
  end

  def render_appeal
    render json: @resource
  end

  def persist_appeal
    build_appeal
    return show if save_appeal
    render_400_with_errors(@resource)
  end

  def build_appeal
    @resource ||= appeal_scope.build
    @resource.assign_attributes(appeal_params)
    authorize @resource
  end

  def save_appeal
    @resource.save
  end

  def appeal_params
    params.require(:data).require(:attributes).permit(Appeal::PERMITTED_ATTRIBUTES)
  end

  def appeal_scope
    Appeal.where(filter_params)
  end

  def authorize_appeal
    authorize @resource
  end

  def permited_filters
    [:account_list_id]
  end
end
