class Api::V2::User::OrganizationAccountsController < Api::V2Controller
  def index
    authorize load_user, :show?
    load_organization_accounts
    render json: @organization_accounts
  end

  def show
    load_organization_account
    authorize_organization_account
    render_organization_account
  end

  def create
    persist_organization_account
  end

  def update
    load_organization_account
    authorize_organization_account
    persist_organization_account
  end

  def destroy
    load_organization_account
    authorize_organization_account
    @organization_account.destroy
    render_200
  end

  private

  def load_organization_accounts
    @organization_accounts ||= organization_account_scope.where(filter_params).to_a
  end

  def load_organization_account
    @organization_account ||= Person::OrganizationAccount.find(params[:id])
  end

  def render_organization_account
    render json: @organization_account
  end

  def persist_organization_account
    build_organization_account
    authorize_organization_account
    return show if save_organization_account
    render_400_with_errors(@organization_account)
  end

  def build_organization_account
    @organization_account ||= organization_account_scope.build
    @organization_account.assign_attributes(organization_account_params)
  end

  def save_organization_account
    @organization_account.save
  end

  def organization_account_params
    params.require(:data).require(:attributes).permit(Person::OrganizationAccount::PERMITTED_ATTRIBUTES)
  end

  def authorize_organization_account
    authorize @organization_account
  end

  def organization_account_scope
    load_user.organization_accounts
  end

  def load_user
    @user ||= current_user
  end

  def permited_filters
    []
  end
end
