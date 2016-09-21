class Api::V1::Preferences::Integrations::KeyAccountsController < Api::V1::BaseController
  def destroy
    load_key_account
    unless key_account_scope.length > 1
      render json: { error: _("If we let you delete that account you won't be able to log in anymore.") }, status: 400
      return
    end
    @key_account.destroy
    render json: { success: true }
  end

  private

  def load_key_account
    @key_account ||= key_account_scope.find(params[:id])
  end

  def key_account_scope
    current_user.key_accounts
  end

  def load_preferences
    {
      organization_accounts: current_user.organization_accounts.map { |acc| { id: acc.id, name: acc.to_s } },
      valid_organization_account: (current_user.organization_accounts.count > 0)
    }
  end
end
