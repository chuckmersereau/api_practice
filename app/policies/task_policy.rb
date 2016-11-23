class TaskPolicy < ApplicationPolicy
  private

  def resource_owner?
    user.account_lists.exists?(id: resource.account_list_id)
  end
end
