class AccountListInvitePolicy < AccountListChildrenPolicy
  private

  def resource_owner?
    resource.account_list == current_account_list &&
      user.account_lists.exists?(id: current_account_list.id)
  end
end
