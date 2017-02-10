module Types
  DesignationProfileType = GraphQL::ObjectType.define do
    name 'DesignationProfile'
    description 'DesignationProfile Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :remoteId, types.String, '', property: :remote_id
    field :user, UserType, '', property: :user
    field :organization, OrganizationType, '', property: :organization
    field :name, types.String, '', property: :name
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :code, types.String, '', property: :code
    field :balance, types.Float, '', property: :balance
    field :balanceUpdatedAt, !types.String, 'The timestamp of the last time this was updated', property: :balance_updated_at
    field :accountList, AccountListType, 'The parent account list', property: :account_list
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
