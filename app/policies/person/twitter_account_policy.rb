class Person::TwitterAccountPolicy < ApplicationPolicy
  private

  def resource_owner?
    resource.person.account_lists.exists?(id: user.account_lists.ids)
  end
end
