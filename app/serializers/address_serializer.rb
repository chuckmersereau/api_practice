class AddressSerializer < ActiveModel::Serializer
  # embed :ids, include: true
  ATTRIBUTES = [:id, :street, :city, :state, :country, :postal_code, :location, :start_date,
                :end_date, :primary_mailing_address, :historic, :geo].freeze

  attributes(*ATTRIBUTES)
end
