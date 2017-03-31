class PledgePolicy < ApplicationPolicy
  private

  def resource_owner?
    user.account_lists.exists?(id: resource.account_list_id) &&
      (resource.contact.nil? || resource.account_list.contacts.exists?(id: resource.contact_id))
  end
end
