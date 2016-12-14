class Person::KeyAccountSerializer < ApplicationSerializer
  type :key_accounts

  attributes :authenticated,
             :downloading,
             :email,
             :first_name,
             :last_download,
             :last_name,
             :primary,
             :remote_id
end
