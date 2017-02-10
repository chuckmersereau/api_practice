module Types
  TwitterAccountType = GraphQL::ObjectType.define do
    name 'TwitterAccount'
    description 'A Twitter Account object'

    field :id, !types.ID, 'The ID for this Twitter Account', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the Twitter Account was created', property: :created_at
    field :primary, types.Boolean, 'Whether or not the Twitter Account is primary [TODO]'
    field :remoteId, !types.ID, 'The ID given by Twitter for the Twitter Account', property: :remote_id
    field :screenName, !types.String, 'The screen name of the Twitter Account', property: :screen_name
    field :updatedAt, !types.String, 'The timestamp that the Twitter Account was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the Twitter Account was last updated', property: :updated_at
  end
end
