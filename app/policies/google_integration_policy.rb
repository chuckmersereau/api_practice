class GoogleIntegrationPolicy < ApplicationPolicy
  def sync?
    resource_owner?
  end

  private

  def resource_owner?
    @user.account_lists.exists?(id: @resource.account_list_id) &&
      @user.google_accounts.exists?(id: @resource.google_account_id)
  end
end
