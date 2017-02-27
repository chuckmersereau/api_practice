module Types
  PrayerLettersAccountType = GraphQL::ObjectType.define do
    name 'PrayerLettersAccount'
    description 'PrayerLettersAccount Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :token, types.String, '', property: :token
    field :validToken, types.Boolean, 'DEFAULT true', property: :valid_token
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :accountList, AccountListType, 'The parent account list', property: :account_list
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end