class UserPolicy < ApplicationPolicy
  def destroy?
    resource != user &&
      belongs_to_same_account_list?
  end

  def show?
    resource_owner? || belongs_to_same_account_list?
  end

  private

  def belongs_to_same_account_list?
    (user.account_lists.ids & resource.account_lists.ids).present?
  end

  def resource_owner?
    user == resource
  end
end
