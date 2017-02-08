class ActivityCommentPolicy < ApplicationPolicy
  private

  def resource_owner?
    user.account_lists.exists?(id: resource.activity.account_list_id)
  end
end
