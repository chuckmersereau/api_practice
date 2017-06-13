class AccountListPolicy < ApplicationPolicy
  def initialize(context, resource)
    @resource = resource
    @user = context.class.name == 'User' ? context : context.user
  end

  private

  def resource_owner?
    @user.account_lists.exists?(id: @resource.id)
  end
end
