class Person::LinkedinAccountSerializer < ApplicationSerializer
  attributes :created_at,
             :authenticated,
             :first_name,
             :last_name,
             :public_url,
             :remote_id,
             :updated_at
end
