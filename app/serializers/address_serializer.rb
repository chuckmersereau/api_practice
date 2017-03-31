class AddressSerializer < ApplicationSerializer
  attributes :street,
             :city,
             :country,
             :end_date,
             :geo,
             :historic,
             :location,
             :metro_area,
             :postal_code,
             :primary_mailing_address,
             :region,
             :remote_id,
             :seasonal,
             :source,
             :start_date,
             :state,
             :valid_values
end
