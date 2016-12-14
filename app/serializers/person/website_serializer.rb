class Person::WebsiteSerializer < ApplicationSerializer
  type :websites

  attributes :created_at,
             :primary,
             :updated_at,
             :url
end
