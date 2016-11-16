class AppealPolicy < ApplicationPolicy
  private

  def resource_owner?
    user.account_lists.ids.include?(resource.account_list_id)
  end
end
