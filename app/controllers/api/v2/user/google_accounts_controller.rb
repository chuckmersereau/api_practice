class Api::V2::User::GoogleAccountsController < Api::V2Controller
  def index
    load_google_accounts
    render json: @google_accounts, meta: meta_hash(@google_accounts), include: include_params, fields: field_params
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
    destroy_key_account
  end

  private

  def destroy_key_account
    @google_account.destroy
    head :no_content
  end

  def load_google_accounts
    @google_accounts = google_account_scope.where(filter_params)
                                           .reorder(sorting_param)
                                           .page(page_number_param)
                                           .per(per_page_param)
  end

  def load_google_account
    @google_account ||= Person::GoogleAccount.find_by!(uuid: params[:id])
  end

  def render_google_account
    render json: @google_account,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_google_account
    build_google_account
    authorize_google_account

    if save_google_account
      render_google_account
    else
      render_400_with_errors(@google_account)
    end
  end

  def build_google_account
    @google_account ||= google_account_scope.build
    @google_account.assign_attributes(google_account_params)
  end

  def save_google_account
    @google_account.save(context: persistence_context)
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

  def permitted_filters
    []
  end
end
