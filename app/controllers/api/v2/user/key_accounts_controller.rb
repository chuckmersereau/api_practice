class Api::V2::User::KeyAccountsController < Api::V2Controller
  def index
    authorize load_user, :show?
    load_key_accounts
    render json: @key_accounts
  end

  def show
    load_key_account
    authorize_key_account
    render_key_account
  end

  def create
    persist_key_account
  end

  def update
    load_key_account
    authorize_key_account
    persist_key_account
  end

  def destroy
    load_key_account
    authorize_key_account
    @key_account.destroy
    render_200
  end

  private

  def load_key_accounts
    @key_accounts ||= key_account_scope.where(filter_params).to_a
  end

  def load_key_account
    @key_account ||= Person::KeyAccount.find(params[:id])
  end

  def render_key_account
    render json: @key_account
  end

  def persist_key_account
    build_key_account
    authorize_key_account
    return show if save_key_account
    render_400_with_errors(@key_account)
  end

  def build_key_account
    @key_account ||= key_account_scope.build
    @key_account.assign_attributes(key_account_params)
  end

  def save_key_account
    @key_account.save
  end

  def key_account_params
    params.require(:data).require(:attributes).permit(Person::KeyAccount::PERMITTED_ATTRIBUTES)
  end

  def authorize_key_account
    authorize @key_account
  end

  def key_account_scope
    load_user.key_accounts
  end

  def load_user
    @user ||= current_user
  end

  def permited_filters
    []
  end
end
