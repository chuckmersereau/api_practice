class Api::V1::Preferences::IntegrationsController < Api::V1::BaseController
  before_action :load_preferences_set

  def index
    load_integration_preferences
    render json: { preferences: @preferences }, callback: params[:callback]
  end

  protected

  def load_preferences_set
    @preference_set = PreferenceSet.new(user: current_user, account_list: current_account_list)
  end

  def load_integration_preferences
    @preferences = {}
    @preferences = @preferences.merge(fetch_google_preferences)
    @preferences = @preferences.merge(fetch_prayer_letters_preferences)
    @preferences = @preferences.merge(fetch_pls_preferences)
  end

  def fetch_google_preferences
    {
      google_accounts: current_user.google_accounts.select(:id, :email),
      valid_google_account: (current_user.google_accounts.count > 0)
    }
  end

  def fetch_prayer_letters_preferences
    {
      prayer_letters_account: current_account_list.prayer_letters_account,
      prayer_letters_account_id: current_account_list.prayer_letters_account.try(:id),
      valid_prayer_letters_account: current_account_list.valid_prayer_letters_account
    }
  end

  def fetch_pls_preferences
    {
      pls_account: current_account_list.pls_account,
      pls_account_id: current_account_list.pls_account.try(:id),
      valid_pls_account: current_account_list.valid_pls_account
    }
  end
end
