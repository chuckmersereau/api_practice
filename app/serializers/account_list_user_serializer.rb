class AccountListUserSerializer < ApplicationSerializer
  attributes :first_name,
             :last_name

  type :users
end
