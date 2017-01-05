class AccountListPolicy < ApplicationPolicy
  def initialize(context, resource)
    @resource = resource
    @user = context.is_a?(User) ? context : context.user
  end

  private

  def resource_owner?
    @user.account_lists.exists?(@resource)
  end
end
