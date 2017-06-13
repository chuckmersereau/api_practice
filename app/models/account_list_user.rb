class AccountListUser < ApplicationRecord
  belongs_to :user
  belongs_to :account_list

  after_destroy :change_user_default_account_list_if_needed

  private

  def change_user_default_account_list_if_needed
    return unless user && user.default_account_list == account_list_id

    user.update(default_account_list: user.account_lists.reload.ids.first)
  end
end
