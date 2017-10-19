class DonationAmountRecommendationPolicy < ApplicationPolicy
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
    user.account_lists.exists?(contact.account_list_id)
  end
end
