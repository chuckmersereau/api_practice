class PhoneNumberPolicy < ApplicationPolicy
  attr_reader :contact, :person

  def initialize(context, resource)
    @user = context.user
    @contact = context.contact
    @resource = resource
    @person = @resource.person
  end

  private

  def resource_owner?
    resource &&
      contact_belongs_to_current_user? &&
      person_belongs_to_contact?
  end

  def contact_belongs_to_current_user?
    user.account_lists.exists?(id: contact.account_list_id)
  end

  def person_belongs_to_contact?
    person.contacts.exists?(id: contact.id)
  end
end
