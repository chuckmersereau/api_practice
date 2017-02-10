module Types
  UserOptions = GraphQL::ObjectType.define do
    name 'UserOption'
    description 'A key-value pair representing a User Option'

    field :id, !types.ID, 'The ID for this User Option', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the User Option was created', property: :created_at
    field :key, !types.String, 'The key of the User Option'
    field :updatedAt, !types.String, 'The timestamp that the User Option was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the User Option was last updated', property: :updated_at
    field :value, types.String, 'The value of the User Option'
  end
end
