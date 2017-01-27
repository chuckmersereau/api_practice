class Api::V2::ConstantsController < Api::V2Controller
  skip_after_action :verify_authorized

  def index
    load_constants
    render_constants
  end

  private

  def load_constants
    @constants ||= ::ConstantList.new
  end

  def render_constants
    render json: @constants, fields: field_params
  end

  def permitted_filters
    []
  end
end
