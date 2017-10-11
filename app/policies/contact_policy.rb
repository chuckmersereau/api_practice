class ContactPolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.is_a?(User) ? context : context.user
    @resource = resource
  end

  def show?
    resource_owner? || coaching_contact?
  end

  private

  def resource_owner?
    user.account_lists.ids & resource_account_list_ids == resource_account_list_ids
  end

  def resource_account_list_ids
    return [@resource.account_list_id] if @resource.is_a?(Contact)
    @resource_account_list_ids ||= @resource.collect(&:account_list_id).uniq
  end

  def coaching_contact?
    coaching_account_list_ids & resource_account_list_ids == resource_account_list_ids
  end

  def coaching_account_list_ids
    @coaching_account_list_ids ||=
      @user.becomes(User::Coach).coaching_contacts.map(&:account_list_id).uniq
  end
end
