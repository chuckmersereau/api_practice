class Person::WebsitePolicy < ApplicationPolicy
  private

  def resource_owner?
    resource.person.account_lists.exists?(id: user.account_lists.ids)
  end
end
