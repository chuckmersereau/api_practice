class Person::KeyAccountSerializer < ApplicationSerializer
  type :key_accounts

  attributes :email,
             :first_name,
             :last_download,
             :last_name,
             :primary,
             :remote_id

  belongs_to :person
end
