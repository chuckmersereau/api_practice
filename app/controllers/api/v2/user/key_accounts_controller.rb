class Api::V2::User::KeyAccountsController < Api::V2Controller
  def index
    load_key_accounts
    render json: @key_accounts, meta: meta_hash(@key_accounts)
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
    destroy_key_account
  end

  private

  def destroy_key_account
    @key_account.destroy
    head :no_content
  end

  def load_key_accounts
    @key_accounts = key_account_scope.where(filter_params)
                                     .reorder(sorting_param)
                                     .page(page_number_param)
                                     .per(per_page_param)
  end

  def load_key_account
    @key_account ||= Person::KeyAccount.find(params[:id])
  end

  def render_key_account
    render json: @key_account,
           status: success_status
  end

  def persist_key_account
    build_key_account
    authorize_key_account

    if save_key_account
      render_key_account
    else
      render_400_with_errors(@key_account)
    end
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
