class Person::FacebookAccountSerializer < ApplicationSerializer
  type :facebook_accounts

  attributes :created_at,
             :first_name,
             :last_name,
             :remote_id,
             :updated_at,
             :username
end
