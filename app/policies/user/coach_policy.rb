class User::CoachPolicy < ApplicationPolicy
  def destroy?
    coaching_one_of_user_account_lists?
  end

  def show?
    resource_owner? || coaching_one_of_user_account_lists?
  end

  private

  def coaching_one_of_user_account_lists?
    (user.account_lists.ids & resource.coaching_account_lists.ids).present?
  end

  def resource_owner?
    user == resource
  end
end
