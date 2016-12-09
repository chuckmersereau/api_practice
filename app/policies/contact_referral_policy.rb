class ContactReferralPolicy < ApplicationPolicy
  attr_reader :contact,
              :resource,
              :user

  def initialize(context, resource)
    @user     = context.user
    @contact  = context.contact
    @resource = resource
  end

  private

  def resource_owner?
    user_has_ownership_of_contact? &&
      referral_referred_by_contact?
  end

  def referral_referred_by_contact?
    resource.referred_by_id == contact.id
  end

  def user_has_ownership_of_contact?
    user.account_lists.exists?(id: contact.account_list_id)
  end
end
