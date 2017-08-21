class OrganizationSerializer < ApplicationSerializer
  attributes :abbreviation,
             :code,
             :country,
             :default_currency_code,
             :logo,
             :name
end
