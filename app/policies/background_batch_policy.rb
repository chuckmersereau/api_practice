class BackgroundBatchPolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.user
    @resource = resource
  end

  private

  def resource_owner?
    resource.user == user
  end
end
