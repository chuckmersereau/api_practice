class Person::TwitterAccountSerializer < ApplicationSerializer
  attributes :primary,
  					 :remote_id,
  					 :screen_name
end
