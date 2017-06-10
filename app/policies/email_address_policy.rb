class EmailAddressPolicy < ApplicationPolicy
  attr_reader :contact
  attr_reader :person

  def initialize(context, resource)
    @contact  = context.contact
    @person   = context.person
    @resource = resource
    @user     = context.user
  end

  private

  def person_has_ownership_of_email_address?(email = resource)
    person.id = email.person_id
  end

  def resource_owner?
    user_can_access_current_persons_email_addresses? &&
      person_has_ownership_of_email_address?
  end

  def user_can_access_current_persons_email_addresses?
    user_is_person? || user_has_ownership_of_person?
  end

  def user_has_ownership_of_person?
    user.account_lists.exists?(id: contact.account_list_id) &&
      person.contacts.exists?(id: contact.id)
  end

  def user_is_person?
    user.id == person.id
  end
end
