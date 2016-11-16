class UserPolicy < ApplicationPolicy
  def destroy?
    resource != user && resource_owner?
  end

  private

  def resource_owner?
    user == resource || (user.account_lists.ids & resource.account_lists.ids).present?
  end
end
