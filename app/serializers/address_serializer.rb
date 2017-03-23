class AddressSerializer < ApplicationSerializer
  attributes :street,
             :city,
             :country,
             :end_date,
             :geo,
             :historic,
             :location,
             :postal_code,
             :primary_mailing_address,
             :source,
             :start_date,
             :state,
             :valid_values
end
