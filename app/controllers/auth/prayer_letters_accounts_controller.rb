class Auth::PrayerLettersAccountsController < ApplicationController
  def create
    auth_hash = request.env['omniauth.auth']
    prayer_letters_account.attributes = {
      oauth2_token: auth_hash.credentials.token,
      valid_token: true
    }
    prayer_letters_account.save
    redirect_to application_close_path(url: integration_preferences_tab_path(tab_id: 'prayerletters'))
  end

  private

  def prayer_letters_account
    @prayer_letters_account ||= current_account_list.prayer_letters_account ||
                                current_account_list.build_prayer_letters_account
  end
end
