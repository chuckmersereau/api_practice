class Api::V2Controller < ApiController
  include Pundit

  before_action :jwt_authorize!
  after_action :verify_authorized, except: :index

  rescue_from Pundit::NotAuthorizedError, with: :render_403

  protected

  def current_account_list
    @current_account_list ||= current_user.account_lists.first
  end

  def current_user
    @current_user ||= User.find(jwt_payload['user_id']) if jwt_payload
  end

  private

  def jwt_authorize!
    raise Exceptions::AuthenticationError unless user_id_in_token?
  rescue JWT::VerificationError, JWT::DecodeError
    raise Exceptions::AuthenticationError
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
    @jwt_payload ||= JsonWebToken.decode(http_token) if http_token
  end
end
