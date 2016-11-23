class MasterAddressSerializer < ApplicationSerializer
  attributes :city,
             :country,
             :postal_code,
             :state,
             :street
end
