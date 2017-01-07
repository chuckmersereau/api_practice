class Api::V2::Constants::OrganizationsController < Api::V2Controller
  def index
    load_organizations
    render_organizations
  end

  private

  def load_organizations
    @organizations ||= ::Constants::OrganizationList.new
  end

  def render_organizations
    render json: @organizations
  end

  def permitted_filters
    []
  end
end
