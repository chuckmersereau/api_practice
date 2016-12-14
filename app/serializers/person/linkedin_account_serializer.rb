class Person::LinkedinAccountSerializer < ApplicationSerializer
  type :linkedin_accounts

  attributes :authenticated,
             :created_at,
             :first_name,
             :last_name,
             :public_url,
             :remote_id,
             :updated_at
end
