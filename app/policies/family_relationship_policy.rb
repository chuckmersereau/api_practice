class FamilyRelationshipPolicy < ApplicationPolicy
  attr_reader :current_contact
  attr_reader :current_person

  def initialize(context, resource)
    @user = context.user
    @current_contact = context.contact
    @resource = resource
  end

  private

  def resource_owner?
    user.account_lists.exists?(id: current_contact.account_list_id) &&
      resource.person.contacts.exists?(id: current_contact.id)
  end
end
