class AccountListPolicy < ApplicationPolicy
  attr_reader :current_account_list

  def initialize(context, resource)
    @user = context.user
    @current_account_list = context.user_data
    @resource = resource
  end

  def destroy?
    user != resource && resource_owner?
  end

  private

  def resource_owner?
    user.can_manage_sharing?(@current_account_list)
  end
end
