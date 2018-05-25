class AccountListPolicy < ApplicationPolicy
  def show?
    resource_owner? || resource_coach?
  end

  private

  def resource_owner?
    user.account_lists.exists?(id: @resource.id)
  end

  def resource_coach?
    coach.coaching_account_lists.exists?(id: @resource.id)
  end
end
