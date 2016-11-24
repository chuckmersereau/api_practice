class NotificationPolicy < AccountListChildrenPolicy
  private

  def resource_owner?
    user.can_manage_sharing?(current_account_list)
  end
end
