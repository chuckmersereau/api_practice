class Person::FacebookAccountPolicy < ApplicationPolicy
  private

  def resource_owner?
    resource.person.account_lists.exists?(id: user.account_lists.pluck(:id))
  end
end
