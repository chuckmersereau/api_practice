class AddressSerializer < ActiveModel::Serializer
  attributes :street,
             :city,
             :country,
             :end_date,
             :geo,
             :historic,
             :location,
             :postal_code,
             :primary_mailing_address,
             :start_date,
             :state
end
