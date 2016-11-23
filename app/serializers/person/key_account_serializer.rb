class Person::KeyAccountSerializer < ApplicationSerializer
  attributes :authenticated,
             :downloading,
             :email,
             :first_name,
             :last_download,
             :last_name,
             :primary,
             :remote_id
end
