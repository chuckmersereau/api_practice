class AccountListInvite < ActiveRecord::Base
  belongs_to :account_list
  belongs_to :user

  def accept_and_destroy(accepting_user)
    account_list.account_list_users.find_or_create_by(user: accepting_user)
    destroy
  end
end
