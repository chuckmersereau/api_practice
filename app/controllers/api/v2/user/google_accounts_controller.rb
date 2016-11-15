class Api::V2::User::GoogleAccountsController < Api::V2::ResourceController
  private

  def resource_scope
    current_user.google_accounts
  end

  def resource_class
    Person::GoogleAccount
  end
end
