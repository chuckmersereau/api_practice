class ApplicationPolicy
  attr_reader :resource, :user, :coach

  def initialize(context, resource)
    @resource = resource
    @user = context.is_a?(User) ? context : context.user
    @coach = @user.becomes(User::Coach)
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

  protected

  def resource_owner?
    raise 'Must Override'
  end

  def resource_coach?
    raise 'Must Override'
  end
end
