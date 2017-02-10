module Types
  OrganizationType = GraphQL::ObjectType.define do
    name 'Organization'
    description 'An Organization object'

    field :id, !types.ID, 'The UUID of the Organization', property: :uuid
    field :name, !types.String, 'The Organization name'
    field :logo, types.String, 'The logo for the Organization'
    field :createdAt, !types.String, 'When the Organization was created', property: :created_at
    field :updatedAt, !types.String, 'The datetime in which the Organization was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Organization was last updated in the database', property: :updated_at
  end
end
