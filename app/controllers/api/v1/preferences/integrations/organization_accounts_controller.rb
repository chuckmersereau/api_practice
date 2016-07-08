class Api::V1::Preferences::Integrations::OrganizationAccountsController < Api::V1::BaseController
  def index
    load_organization_accounts
    render json: { organization_accounts: @organization_accounts.map { |acc| { id: acc.id, name: acc.organization.name, username: acc.username, api_class: acc.organization.api_class } } }, callback: params[:callback]
  end

  def create
    build_organization_account
    return render json: { success: true }, status: 201 if save_organization_account
    render json: { errors: @organization_account.errors.full_messages }, status: 400
  end

  def update
    load_organization_account
    build_organization_account
    return render json: { success: true } if save_organization_account
    render json: { errors: @organization_account.errors.full_messages }, status: 400
  end

  def destroy
    load_organization_account
    @organization_account.destroy
    render json: { success: true }
  end

  private

  def load_organization_accounts
    @organization_accounts ||= organization_account_scope.includes(:organization).order('organizations.name').all
  end

  def load_organization_account
    @organization_account ||= organization_account_scope.find(params[:id])
  end

  def build_organization_account
    @organization_account ||= organization_account_scope.build
    @organization_account.attributes = organization_account_params
    @organization = @organization_account.organization
  end

  def save_organization_account
    return false unless @organization
    @organization_account.save
  rescue ActiveRecord::RecordNotUnique
    save_account_error format(_('Error connecting: you are already connected as %{org_account}'),
                              org_account: @organization_account)
  rescue DataServerError => e
    Rollbar.info(e)
    save_account_error e.message
  rescue RuntimeError => e
    Rollbar.error(e)
    save_account_error format(_('Error connecting to %{org_name} server'), org_name: @organization.name)
  end

  def save_account_error(message)
    @organization_account.errors.add(:base, message)
    false
  end

  def organization_account_params
    return {} unless params[:organization_account]
    organization_account_params = params[:organization_account]
    organization_account_params.permit(:username, :password, :organization_id)
  end

  def organization_account_scope
    current_user.organization_accounts
  end
end
