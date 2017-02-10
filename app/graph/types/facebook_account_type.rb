module Types
  FacebookAccountType = GraphQL::ObjectType.define do
    name 'FacebookAccount'
    description 'A Facebook Account object'

    field :id, !types.ID, 'The ID for this FacebookAccount', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the Facebook Account was created', property: :created_at
    field :firstName, types.String, 'The first name of the Facebook Account', property: :first_name
    field :lastName, types.String, 'The last name of the Facebook Account', property: :last_name
    field :remoteId, !types.ID, 'The ID given by Facebook for the Facebook Account', property: :remote_id
    field :updatedAt, !types.String, 'The timestamp that the Facebook Account was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the Facebook Account was last updated', property: :updated_at
    field :username, !types.String, 'The username on the Facebook Account'
  end
end
