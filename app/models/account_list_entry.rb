class AccountListEntry < ApplicationRecord
  belongs_to :account_list
  belongs_to :designation_account
end
