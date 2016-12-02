class Person::WebsiteSerializer < ApplicationSerializer
  attributes :created_at,
             :primary,
             :updated_at,
             :url
end
