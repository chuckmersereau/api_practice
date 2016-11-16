class Api::V2::UsersController < Api::V2::ResourceController
  private

  def resource_class
    User
  end

  def load_resource
    @resource ||= current_user
  end
end
