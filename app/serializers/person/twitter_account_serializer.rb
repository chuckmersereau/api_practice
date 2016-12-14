class Person::TwitterAccountSerializer < ApplicationSerializer
  type :twitter_accounts

  attributes :created_at,
             :primary,
             :remote_id,
             :screen_name,
             :updated_at
end
