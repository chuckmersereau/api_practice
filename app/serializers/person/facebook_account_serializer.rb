class Person::FacebookAccountSerializer < ApplicationSerializer
  attributes :remote_id, :first_name, :last_name, :username
end
