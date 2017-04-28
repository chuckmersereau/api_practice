class AccountListChildrenPolicy < ApplicationPolicy
  attr_accessor :current_account_list

  def initialize(context, resource)
    @resource = resource
    @user = context.user
    @current_account_list = context.account_list
  end

  private

  def resource_owner?
    user.account_lists.exists?(current_account_list)
  end
end
