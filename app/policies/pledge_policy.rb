class PledgePolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.is_a?(User) ? context : context.user
    @resource = resource
  end

  def show?
    resource_owner? || coaching_pledge?
  end

  private

  def resource_owner?
    user.account_lists.exists?(id: resource.account_list_id) &&
      (resource.contact.nil? || resource.account_list.contacts.exists?(id: resource.contact_id))
  end

  def coaching_pledge?
    @user.becomes(User::Coach)
         .coaching_account_lists
         .exists?(resource.account_list_id)
  end
end
