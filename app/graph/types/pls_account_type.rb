module Types
  PlsAccountType = GraphQL::ObjectType.define do
    name 'PlsAccount'
    description 'PlsAccount Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :accountList, AccountListType, 'The parent account list', property: :account_list
    field :oauth2Token, types.String, '', property: :oauth2token
    field :validToken, types.Boolean, 'DEFAULT true', property: :valid_token
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
