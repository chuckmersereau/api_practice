class AccountListPolicy < ApplicationPolicy
  def initialize(context, resource)
    @resource = resource
    return @user = context if context.is_a?(User)
    @user = context.user
    @current_account_list = context.user_data
  end

  private

  def resource_owner?
    user.account_lists.exists?(@resource)
  end
end
