class PlsAccountsController < ApplicationController
  def create
    auth_hash = request.env['omniauth.auth']

    pls_account.attributes = {
      oauth2_token: auth_hash.credentials.token,
      valid_token: true
    }
    pls_account.save
    flash[:notice] = _('MPDX is now uploading your newsletter recipients to myletterservice.org.')

    redirect_to integrations_settings_path
  end

  def destroy
    current_account_list.pls_account.destroy
    return render nothing: true if request.xhr?
    redirect_to integrations_settings_path
  end

  def sync
    flash[:notice] = _('MPDX is now uploading your newsletter recipients to myletterservice.org.')
    pls_account.queue_subscribe_contacts
    redirect_to :back
  end

  private

  def pls_account
    @pls_account ||= current_account_list.pls_account || current_account_list.build_pls_account
  end
end
