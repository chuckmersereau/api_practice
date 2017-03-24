class PersonPolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.user
    @contact_scope = context.respond_to?(:contact_scope) ? context.contact_scope : nil
    @contacts = resource.contacts
    @resource = resource
  end

  def create?
    # We trust that the created Person will be associated to a Contact in the contact_scope
    @contacts = @contact_scope
    contacts_belongs_to_user?
  end

  private

  def resource_owner?
    resource_is_user? || resource_belongs_to_user?
  end

  def resource_is_user?
    resource.id == user.id
  end

  def resource_belongs_to_user?
    contacts_belongs_to_user? &&
      Person.exists?(id: resource.id) &&
      ContactPerson.exists?(contact_id: @contacts.collect(&:id), person_id: resource.id)
  end

  def contacts_belongs_to_user?
    @contacts.present? &&
      (contacts_account_list_ids & user.account_lists.ids == contacts_account_list_ids)
  end

  def contacts_account_list_ids
    @contacts_account_list_ids ||= @contacts.collect(&:account_list_id).uniq
  end
end
