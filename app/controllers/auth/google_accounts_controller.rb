class Auth::GoogleAccountsController < ApplicationController
  def create
    load_google_account
    redirect_to application_close_path(url: integration_preferences_tab_path(tab_id: 'google'))
  end

  private

  def load_google_account
    @google_account ||= Person::GoogleAccount.find_or_create_from_auth(request.env['omniauth.auth'], current_user)
  end
end
