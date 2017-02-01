class MailChimpAccountPolicy < ApplicationPolicy
  def sync?
    resource_owner?
  end

  def export?
    resource_owner?
  end

  private

  def resource_owner?
    user.account_lists.exists?(id: resource.account_list_id)
  end
end
