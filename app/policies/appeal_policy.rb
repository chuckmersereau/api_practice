class AppealPolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.user
    @resource = resource
  end

  private

  def resource_owner?
    user.account_lists.exists?(id: resource.account_list_id)
  end
end
