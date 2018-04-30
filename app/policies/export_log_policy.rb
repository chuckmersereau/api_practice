class ExportLogPolicy < ApplicationPolicy
  def resource_owner?
    resource.user == user && resource.active
  end
end
