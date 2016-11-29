class ApplicationPolicy
  attr_reader :user, :resource

  def initialize(user, resource)
    @user = user
    @resource = resource
  end

  def show?
    resource_owner?
  end

  def create?
    resource_owner?
  end

  def update?
    resource_owner?
  end

  def destroy?
    resource_owner?
  end
end
