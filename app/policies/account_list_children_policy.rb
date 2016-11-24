class AccountListChildrenPolicy < ApplicationPolicy
  attr_accessor :current_account_list

  def initialize(context, resource)
    @resource = resource
    @user = context.user
    @current_account_list = context.user_data
  end

  private

  def resource_owner?
    resource.account_list == current_account_list &&
      user.account_lists.exists?(current_account_list)
  end
end
