class Person::LinkedinAccountSerializer < ApplicationSerializer
  attributes :authenticated,
  					 :created_at,
             :first_name,
             :last_name,
             :public_url,
             :remote_id,
             :updated_at
end
