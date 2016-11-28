class Person::LinkedinAccountSerializer < ApplicationSerializer
  attributes :authenticated,
  					 :first_name, 
  					 :last_name, 
  					 :public_url,
  					 :remote_id
end
