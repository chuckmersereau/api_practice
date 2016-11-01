class Api::V2::BaseController < ActionController::API
  before_action :jwt_authorize!

  def current_user
    @current_user ||= User.find(jwt_payload['user_id'])
  end

  private

  def jwt_authorize!
    unauthorized unless user_id_in_token?
  rescue JWT::VerificationError, JWT::DecodeError
    unauthorized
  end

  def unauthorized
    render json: { errors: ['Not Authenticated'] }, status: :unauthorized
  end

  def user_id_in_token?
    http_token && jwt_payload && jwt_payload['user_id'].to_i
  end

  def http_token
    @http_token ||= auth_header.split(' ').last if auth_header.present?
  end

  def auth_header
    request.headers['Authorization']
  end

  def jwt_payload
    @jwt_payload ||= JsonWebToken.decode(http_token)
  end
end
