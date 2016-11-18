class Api::V2::ResourceController < Api::V2Controller
  include ParamsFilters
  
  def index
    load_resources
    render json: @resources
  end

  def show
    render_resource
  end

  def create
    persist_resource
  end

  def update
    persist_resource
  end

  def destroy
    @resource.destroy
    render_200
  end

  private

  def persist_resource
    build_resource
    return show if save_resource
    render_400_with_errors(@resource)
  end

  def load_resources
    @resources ||= resource_scope.to_a
  end

  def load_resource
    @resource ||= resource_class.find(params[:id])
  end

  def authorize_resource
    authorize @resource
  end

  def render_resource
    render json: @resource
  end

  def build_resource
    @resource ||= resource_scope.build
    @resource.assign_attributes(resource_params)
    authorize @resource
  end

  def save_resource
    @resource.save
  end

  def resource_params
    transform_params_field_names
    params.require(:data).require(:attributes).permit(resource_attributes)
  end

  def resource_attributes
    "#{resource_class}::PERMITTED_ATTRIBUTES".constantize
  end
end
