class FamilyRelationshipPolicy < ApplicationPolicy
  attr_reader :current_contact
  attr_reader :current_person

  def initialize(context, resource)
    @user = context.user
    @current_contact = context.user_data
    @resource = resource
  end

  private

  def resource_owner?
    user.account_lists.ids.include?(current_contact.account_list_id) &&
      resource.person.contacts.ids.include?(current_contact.id)
  end
end