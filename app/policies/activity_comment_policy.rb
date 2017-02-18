class ActivityCommentPolicy < ApplicationPolicy
  private

  def resource_owner?
    person_authorized? &&
      user.account_lists.exists?(id: resource.activity.account_list_id)
  end

  def person_authorized?
    resource.person_id.blank? ||
      user.account_lists.joins(:people).exists?(people: { id: resource.person_id })
  end
end
