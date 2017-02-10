module Types
  PersonOptionType = GraphQL::ObjectType.define do
    name 'PersonOption'
    description 'PersonOption Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :key, !types.String, '', property: :key
    field :value, types.String, '', property: :value
    field :userId, types.Int, '', property: :user_id
    field :id, !types.ID, 'The UUID', property: :uuid
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
  end
end
