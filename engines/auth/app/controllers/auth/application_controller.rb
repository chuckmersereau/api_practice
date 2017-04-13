module Auth
  class ApplicationController < ActionController::Base
    class AuthenticationError < StandardError; end
    rescue_from AuthenticationError, with: :render_401
    protect_from_forgery with: :exception

    protected

    def render_401
      render '401', status: 401
    end

    def jwt_authorize!
      raise AuthenticationError unless user_id_in_token?
    rescue JWT::VerificationError, JWT::DecodeError
      raise AuthenticationError
    end

    def current_user
      @current_user ||= session['warden.user.user.key']
    end

    def current_account_list
      @account_list ||= current_user.account_lists
                                    .find_by(uuid: session['account_list_id'])
    end

    def user_id_in_token?
      http_token && jwt_payload && jwt_payload['user_uuid']
    end

    def http_token
      return @http_token ||= auth_header.split(' ').last if auth_header.present?
      return @http_token ||= params[:access_token] if params[:access_token]
    end

    def auth_header
      request.headers['Authorization']
    end

    def jwt_payload
      @jwt_payload ||= JsonWebToken.decode(http_token) if http_token
    end
  end
end
