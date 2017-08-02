class Api::V2::Admin::OrganizationsController < Api::V2Controller
  skip_after_action :verify_authorized

  def create
    authorize_organization
    persist_organization
  end

  private

  def authorize_organization
    raise Pundit::NotAuthorizedError,
          'must be admin level user to create organizations' unless current_user.admin
  end

  def persist_organization
    build_organization
    if save_organization
      render_organization
    else
      render_with_resource_errors(@organization)
    end
  end

  def render_organization
    render json: @organization,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def build_organization
    @organization ||= organization_scope.create
    @organization.attributes = organization_params
  end

  def save_organization
    @organization.save
  end

  def organization_scope
    ::Organization
  end

  def organization_params
    params.require(:organization)
          .permit(:name, :org_help_url, :country).merge(
            query_ini_url: "#{SecureRandom.hex(8)}.example.com",
            api_class: 'OfflineOrg',
            addresses_url: 'example.com'
          )
  end
end
