module Types
  AddressType = GraphQL::ObjectType.define do
    name 'Address'
    description 'An Address object'

    field :id, !types.ID, 'The UUID of the Address', property: :uuid
    field :createdAt, !types.String, 'The datetime when the Address was created', property: :created_at
    field :city, types.String, 'The city of the Address', property: :city
    field :country, types.String, 'The country of the Address', property: :country
    field :endDate, types.String, 'When the Address owner stopped living at the Address', property: :end_date
    field :geo, types.String, 'The geolocation numbers for this Address'
    field :historic, types.Boolean, 'Whether or not the Address is still in use'
    field :location, types.String, 'The type of Address, ie: "Home", "Work", etc', property: :location
    field :postalCode, types.String, 'The postal code for the Address', property: :postal_code
    field :primaryMailingAddress, types.Boolean, 'Whether or not this Address is the primary Address for its owner', property: :primary_mailing_address
    field :startDate, types.String, 'When the Address owner started living at the Address', property: :start_date
    field :state, types.String, 'The state where the Address resides'
    field :street, types.String, 'The street on which the Address resides'
    field :updatedAt, !types.String, 'The datetime in which the Address was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Address was last updated in the database', property: :updated_at
  end
end
