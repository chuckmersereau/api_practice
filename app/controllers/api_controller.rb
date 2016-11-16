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

  def render_400_with_errors(resource_or_errors)
    render json: { success: false, errors: fetch_errors(resource_or_errors) }, status: 400
  end

  def fetch_errors(resource_or_errors)
    if resource_or_errors.is_a?(Hash)
      resource_or_errors
    else
      resource_or_errors.errors.full_messages
    end
  end
end
