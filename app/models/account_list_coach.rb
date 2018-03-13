class AccountListCoach < ApplicationRecord
  belongs_to :coach, class_name: 'User::Coach'
  belongs_to :account_list
end
