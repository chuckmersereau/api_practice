module Types
  CompanyType = GraphQL::ObjectType.define do
    name 'Company'
    description 'Company Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :name, types.String, '', property: :name
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :street, types.String, '', property: :street
    field :city, types.String, '', property: :city
    field :state, types.String, '', property: :state
    field :postalCode, types.String, '', property: :postal_code
    field :country, types.String, '', property: :country
    field :phoneNumber, types.String, '', property: :phone_number
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
