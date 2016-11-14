class Api::V2::UsersController < Api::V2::ResourceController
  private

  def resource_attributes
    User::PERMITTED_ATTRIBUTES
  end

  def load_resource
    @resource ||= current_user
  end
end
