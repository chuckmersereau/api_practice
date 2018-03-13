module Auth
  class Provider::BaseController < ApplicationController
    def create
      find_or_create_account
      redirect_to session['redirect_to'] || 'http://mpdx.org'
      reset_session
    end

    protected

    def find_or_create_account
      raise 'MUST OVERRIDE'
    end

    def auth_hash
      request.env['omniauth.auth']
    end

    def current_account_list
      @account_list ||= current_user.account_lists
                                    .find_by(id: session['account_list_id'])
    end
  end
end
