require_dependency 'auth/application_controller'

module Auth
  class UserAccountsController < ApplicationController
    before_action :jwt_authorize!

    def create
      sign_in(:user, fetch_current_user)
      session['redirect_to'] = params[:redirect_to]
      session['account_list_id'] = params[:account_list_id]
      redirect_to "/auth/#{params[:provider]}"
    end

    def failure
      render_401
    end

    private

    def fetch_current_user
      @current_user ||= User.find_by_uuid_or_raise!(jwt_payload['user_uuid']) if jwt_payload
    end
  end
end
