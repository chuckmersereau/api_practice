class AccountListPolicy < ApplicationPolicy
  def initialize(context, resource)
    @resource = resource
    @user = context.class.name == 'User' ? context : context.user
  end

  def show?
    super || coaching_account_list?
  end

  private

  def resource_owner?
    @user.account_lists.exists?(id: @resource.id)
  end

  def coaching_account_list?
    @user.becomes(User::Coach)
         .coaching_account_lists
         .where(id: @resource.id)
         .any?
  end
end
