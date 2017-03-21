class ContactPolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.user
    @resource = resource
  end

  private

  def resource_owner?
    user.account_lists.ids & resource_account_list_ids == resource_account_list_ids
  end

  def resource_account_list_ids
    return [@resource.account_list_id] if @resource.is_a?(Contact)
    @resource_account_list_ids ||= @resource.collect(&:account_list_id).uniq
  end
end
