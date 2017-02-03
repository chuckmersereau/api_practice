class User::OptionPolicy < ApplicationPolicy
  private

  def resource_owner?
    resource.user_id == user.id
  end
end
