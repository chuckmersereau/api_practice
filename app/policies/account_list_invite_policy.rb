class AccountListInvitePolicy < AccountListPolicy
  def index?
    resource_owner?
  end

  def create?
    resource_owner?
  end
end
