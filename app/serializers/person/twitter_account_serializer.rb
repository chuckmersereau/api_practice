class Person::TwitterAccountSerializer < ApplicationSerializer
  attributes :created_at,
             :primary,
             :remote_id,
             :screen_name,
             :updated_at
end
