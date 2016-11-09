class ApiController < ActionController::API
  rescue_from Exceptions::AuthenticationError, with: :unauthorized

  protected

  def unauthorized
    render json: { errors: ['Unauthorized'] }, status: :unauthorized
  end
end
