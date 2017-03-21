class Person::LinkedinAccountSerializer < ApplicationSerializer
  type :linkedin_accounts

  attributes :created_at,
             :public_url,
             :updated_at
end
