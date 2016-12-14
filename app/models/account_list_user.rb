class AccountListUser < ApplicationRecord
  has_paper_trail on: [:destroy]

  belongs_to :user
  belongs_to :account_list
end
