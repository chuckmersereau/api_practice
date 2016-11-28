class Person::FacebookAccountSerializer < ApplicationSerializer
  attributes :first_name, 
  					 :last_name,
  					 :remote_id,
  					 :username
end
