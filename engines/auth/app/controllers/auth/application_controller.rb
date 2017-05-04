module Auth
  class ApplicationController < ActionController::Base
    class AuthenticationError < StandardError; end
    rescue_from AuthenticationError, with: :render_401
    protect_from_forgery with: :exception

    protected

    def current_user
      @current_user ||= warden.user(:user)
      raise AuthenticationError unless @current_user
      @current_user
    end

    def render_401
      render '401', status: 401
    end
  end
end
