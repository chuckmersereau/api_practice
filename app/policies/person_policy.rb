class PersonPolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.user
    @current_contact = context.contact
    @resource = resource
  end

  def create?
    current_contact_belongs_to_user?
  end

  private

  def resource_owner?
    resource_is_user? || resource_belongs_to_user?
  end

  def resource_is_user?
    resource.id == user.id
  end

  def resource_belongs_to_user?
    current_contact_belongs_to_user? && @current_contact.people.exists?(id: resource.id)
  end

  def current_contact_belongs_to_user?
    user.account_lists.exists?(id: @current_contact.account_list_id)
  end
end
