class ApiController < ActionController::API
  rescue_from Exceptions::AuthenticationError, with: :render_401
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  protected

  def render_200
    render json: { success: true }, status: 200
  end

  def render_404
    render json: { error: 'Not Found' }, status: 404
  end

  def render_403
    render json: { error: 'Forbidden' }, status: 403
  end

  def render_401
    render json: { error: 'Unauthorized' }, status: 401
  end

  def render_400
    render json: { success: false }, status: 400
  end

  def render_400_with_errors(resource)
    render json: { success: false, errors: resource.errors.full_messages }, status: 400
  end
end
