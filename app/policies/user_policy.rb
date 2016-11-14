class UserPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def destroy?
    resource != user
  end

  private

  def resource_owner?
    resource == user
  end
end
