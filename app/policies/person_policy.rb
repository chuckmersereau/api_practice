class PersonPolicy < ApplicationPolicy
  def initialize(context, resource)
    @user = context.user
    @contacts = context.respond_to?(:contacts) ? context.contacts : [context.contact]
    @resource = resource
  end

  def create?
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
    user.account_lists.ids & contacts_account_list_ids == contacts_account_list_ids
  end

  def contacts_account_list_ids
    @contacts_account_list_ids ||= @contacts.collect(&:account_list_id).uniq
  end
end
