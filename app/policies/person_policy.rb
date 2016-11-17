class PersonPolicy < ApplicationPolicy
  private

  def resource_owner?
    resource.person_id == user.id
  end
end