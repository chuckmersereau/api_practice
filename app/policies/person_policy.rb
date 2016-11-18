class PersonPolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.user
    @current_contact = context.contact
    @resource = resource
  end

  private

  def resource_owner?
    resource.id == user.id || resource_belongs_to_user?
  end

  def resource_belongs_to_user?
    user.account_lists.exists?(id: @current_contact.account_list_id) &&
      @current_contact.people.exists?(id: resource.id)
  end
end
