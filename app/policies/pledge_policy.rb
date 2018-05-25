class PledgePolicy < ApplicationPolicy
  def show?
    resource_owner? || resource_coach?
  end

  private

  def resource_owner?
    user.account_lists.exists?(id: resource.account_list_id) &&
      (resource.contact.nil? || resource.account_list.contacts.exists?(id: resource.contact_id))
  end

  def resource_coach?
    coach.coaching_account_lists.exists?(resource.account_list_id)
  end
end
