module Types
  LinkedinAccountType = GraphQL::ObjectType.define do
    name 'LinkedInAccount'
    description 'A LinkedIn Account object'

    field :id, !types.ID, 'The ID for this LinkedIn Account', property: :uuid
    field :authenticated, !types.Boolean, 'Whether or not the LinkedIn Account is authenticated'
    field :createdAt, !types.String, 'The timestamp that the LinkedIn Account was created', property: :created_at
    field :firstName, types.String, 'The first name of the LinkedIn Account', property: :first_name
    field :lastName, types.String, 'The last name of the LinkedIn Account', property: :last_name
    field :publicUrl, !types.String, 'The public URL of the LinkedIn Account', property: :public_url
    field :remoteId, !types.ID, 'The ID given by LinkedIn for the LinkedIn Account', property: :remote_id
    field :updatedAt, !types.String, 'The timestamp that the LinkedIn Account was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the LinkedIn Account was last updated', property: :updated_at
  end
end
