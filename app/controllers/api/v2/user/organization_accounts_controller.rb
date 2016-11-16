class Api::V2::User::OrganizationAccountsController < Api::V2::ResourceController
  private

  def resource_scope
    current_user.organization_accounts
  end

  def resource_class
    Person::OrganizationAccount
  end
end
