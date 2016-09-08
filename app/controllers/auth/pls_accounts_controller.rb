class Auth::PlsAccountsController < ApplicationController
  def create
    auth_hash = request.env['omniauth.auth']
    pls_account.attributes = {
      oauth2_token: auth_hash.credentials.token,
      valid_token: true
    }
    pls_account.save
    redirect_to application_close_path(url: integration_preferences_tab_path(tab_id: 'myletterservice'))
  end

  private

  def pls_account
    @pls_account ||= current_account_list.pls_account || current_account_list.build_pls_account
  end
end
