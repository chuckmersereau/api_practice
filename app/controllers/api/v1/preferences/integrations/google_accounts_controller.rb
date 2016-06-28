class Api::V1::Preferences::Integrations::GoogleAccountsController < Api::V1::BaseController
  def destroy
    load_google_account
    @google_account.destroy
    render json: { success: true }
  end

  private

  def load_google_account
    @google_account ||= google_account_scope.find(params[:id])
  end

  def google_account_scope
    current_user.google_accounts
  end
end
