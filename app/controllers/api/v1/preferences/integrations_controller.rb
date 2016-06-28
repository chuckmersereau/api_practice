class Api::V1::Preferences::IntegrationsController < Api::V1::Preferences::BaseController
  protected

  def load_preferences
    @preferences ||= {}
    load_google_preferences
    load_prayer_letters_preferences
    load_pls_preferences
  end

  private

  def load_google_preferences
    @preferences.merge!(
      google_accounts: current_user.google_accounts.select(:id, :email),
      valid_google_account: (current_user.google_accounts.count > 0)
    )
  end

  def load_prayer_letters_preferences
    @preferences.merge!(
      prayer_letters_account: current_account_list.prayer_letters_account,
      prayer_letters_account_id: current_account_list.prayer_letters_account.try(:id),
      valid_prayer_letters_account: current_account_list.valid_prayer_letters_account
    )
  end

  def load_pls_preferences
    @preferences.merge!(
      pls_account: current_account_list.pls_account,
      pls_account_id: current_account_list.pls_account.try(:id),
      valid_pls_account: current_account_list.valid_pls_account
    )
  end
end
