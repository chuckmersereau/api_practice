module Types
  WebsiteType = GraphQL::ObjectType.define do
    name 'Website'
    description 'A Website object'

    field :id, !types.ID, 'The ID for this Website record', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the Website record was created', property: :created_at
    field :primary, types.Boolean, 'Whether or not the Website is primary [TODO]'
    field :url, types.String, 'The URL of the Website'
    field :updatedAt, !types.String, 'The timestamp that the Website record was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the Website record was last updated', property: :updated_at
  end
end
