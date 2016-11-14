class Api::V2::User::KeyAccountsController < Api::V2::ResourceController
  private

  def resource_scope
    current_user.key_accounts
  end

  def resource_attributes
    Person::KeyAccount::PERMITTED_ATTRIBUTES
  end
end
