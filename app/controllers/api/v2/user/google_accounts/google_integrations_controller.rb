class Api::V2::User::GoogleAccounts::GoogleIntegrationsController < Api::V2Controller
  def index
    authorize load_google_account, :show?
    load_google_integrations
    render json: @google_integrations,
           meta: meta_hash(@google_integrations),
           include: include_params,
           fields: field_params
  end

  def show
    load_google_integration
    authorize_google_integration
    render_google_integration
  end

  def create
    persist_google_integration
  end

  def update
    load_google_integration
    authorize_google_integration
    persist_google_integration
  end

  def destroy
    load_google_integration
    authorize_google_integration
    destroy_google_integration
  end

  def sync
    load_google_integration
    authorize_google_integration
    @google_integration.queue_sync_data(params[:integration])
    render_200
  end

  private

  def destroy_google_integration
    @google_integration.destroy
    head :no_content
  end

  def load_google_integrations
    @google_integrations = google_integration_scope
                           .reorder(sorting_param)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def load_google_integration
    @google_integration ||= GoogleIntegration.find_by!(id: params[:id])
  end

  def render_google_integration
    render json: @google_integration,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_google_integration
    build_google_integration
    authorize_google_integration

    if save_google_integration
      render_google_integration
    else
      render_with_resource_errors(@google_integration)
    end
  end

  def build_google_integration
    @google_integration ||= google_integration_scope.build
    @google_integration.assign_attributes(google_integration_params)
  end

  def authorize_google_integration
    authorize load_google_account, :show?
    authorize @google_integration
  end

  def save_google_integration
    @google_integration.save(context: persistence_context)
  end

  def google_integration_params
    params
      .require(:google_integration)
      .permit(GoogleIntegration::PERMITTED_ATTRIBUTES)
      .tap do |permit_params| # Permit the Array attributes to be set to anything, including nil (so that the client can empty the Array).
        permit_params[:email_blacklist] = params[:google_integration][:email_blacklist] if params[:google_integration].keys.include?('email_blacklist')
        permit_params[:calendar_integrations] = params[:google_integration][:calendar_integrations] if params[:google_integration].keys.include?('calendar_integrations')
      end
  end

  def google_integration_scope
    current_user.google_integrations.where(account_list: account_lists, google_account: load_google_account)
  end

  def load_google_account
    @google_account ||= Person::GoogleAccount.find_by!(id: params[:google_account_id])
  end

  def permitted_filters
    [:account_list_id]
  end
end
