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
  end
end
