class Api::V1::Preferences::Integrations::OrganizationsController < Api::V1::BaseController
  def index
    load_organizations
    render json: @organizations.as_json(only: [:id, :api_class, :name]), callback: params[:callback]
  end

  private

  def load_organizations
    @organizations ||= organization_scope.all
  end

  def organization_scope
    ::Organization.active.order('name')
  end
end
