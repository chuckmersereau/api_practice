require_dependency 'auth/application_controller'

module Auth
  class UserAccountsController < ApplicationController
    before_action :jwt_authorize!

    def create
      session.clear
      warden.set_user(fetch_current_user, scope: :user)
      session['redirect_to'] = params[:redirect_to]
      session['account_list_id'] = params[:account_list_id]
      if params[:provider] == 'donorhub'
        organization = Organization.find_by!(id: params[:organization_id])
        redirect_to "/auth/donorhub?oauth_url=#{URI.encode(organization.oauth_url)}"
      elsif params[:provider] == 'sidekiq'
        raise AuthenticationError unless current_user.developer
        redirect_to '/sidekiq'
      else
        redirect_to "/auth/#{params[:provider]}"
      end
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
      @current_user ||= User.find_by!(id: jwt_payload['user_id']) if jwt_payload
    end
  end
end
