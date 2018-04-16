class NotificationPreferencePolicy < ApplicationPolicy
  def initialize(context, resource)
    @resource = resource
    @user = context.user
  end

  private

  def resource_owner?
    resource.user == user && user.account_lists.include?(resource.account_list)
  end
end
