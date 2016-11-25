class Api::V2::User::GoogleAccountsController < Api::V2Controller
  def index
    authorize load_user, :show?
    load_google_accounts
    render json: @google_accounts
  end

  def show
    load_google_account
    authorize_google_account
    render_google_account
  end

  def create
    persist_google_account
  end

  def update
    load_google_account
    authorize_google_account
    persist_google_account
  end

  def destroy
    load_google_account
    authorize_google_account
    @google_account.destroy
    render_200
  end

  private

  def load_google_accounts
    @google_accounts ||= google_account_scope.where(filter_params).to_a
  end

  def load_google_account
    @google_account ||= Person::GoogleAccount.find(params[:id])
  end

  def render_google_account
    render json: @google_account
  end

  def persist_google_account
    build_google_account
    authorize_google_account
    return show if save_google_account
    render_400_with_errors(@google_account)
  end

  def build_google_account
    @google_account ||= google_account_scope.build
    @google_account.assign_attributes(google_account_params)
  end

  def save_google_account
    @google_account.save
  end

  def google_account_params
    params.require(:data).require(:attributes).permit(Person::GoogleAccount::PERMITTED_ATTRIBUTES)
  end

  def authorize_google_account
    authorize @google_account
  end

  def google_account_scope
    load_user.google_accounts
  end

  def load_user
    @user ||= current_user
  end

  def permited_filters
    []
  end
end
