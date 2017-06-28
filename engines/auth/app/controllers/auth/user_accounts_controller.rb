require_dependency 'auth/application_controller'

module Auth
  class UserAccountsController < ApplicationController
    before_action :jwt_authorize!

    def create
      session.clear
      warden.set_user(fetch_current_user, scope: :user)
      session['redirect_to'] = params[:redirect_to]
      session['account_list_id'] = params[:account_list_id]
      redirect_to "/auth/#{params[:provider]}"
    end

    def failure
      raise AuthenticationError
    end

    private

    def jwt_authorize!
      raise AuthenticationError unless user_id_in_token?
    rescue JWT::VerificationError, JWT::DecodeError
      raise AuthenticationError
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

    def fetch_current_user
      @current_user ||= User.find_by_uuid_or_raise!(jwt_payload['user_uuid']) if jwt_payload
    end
  end
end