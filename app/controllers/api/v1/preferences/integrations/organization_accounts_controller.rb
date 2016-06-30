class Api::V1::Preferences::Integrations::OrganizationAccountsController < Api::V1::BaseController
  def index
    load_organization_accounts
    render json: { organization_accounts: @organization_accounts.map { |acc| { id: acc.id, name: acc.to_s, api_class: acc.organization.api_class } } }, callback: params[:callback]
  end

  def destroy
    load_organization_account
    @organization_account.destroy
    render json: { success: true }
  end

  private

  def load_organization_accounts
    @organization_accounts ||= organization_account_scope.includes(:organization).all
  end

  def load_organization_account
    @organization_account ||= organization_account_scope.find(params[:id])
  end

  def organization_account_scope
    current_user.organization_accounts
  end
end
