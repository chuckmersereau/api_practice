class DesignationProfileAccount < ApplicationRecord
  belongs_to :designation_profile
  belongs_to :designation_account

  after_create :create_account_list_entry

  private

  def create_account_list_entry
    account_list = designation_profile.account_list
    account_list.designation_accounts << designation_account if account_list && !account_list.designation_accounts.include?(designation_account)
  end
end
