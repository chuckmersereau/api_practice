class OrganizationSerializer < ApplicationSerializer
  attributes :abbreviation,
             :code,
             :country,
             :default_currency_code,
             :logo,
             :name,
             :gift_aid_percentage,
             :oauth

  def oauth
    object.oauth?
  end
end
