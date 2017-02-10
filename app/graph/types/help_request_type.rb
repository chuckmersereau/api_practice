module Types
  HelpRequestType = GraphQL::ObjectType.define do
    name 'HelpRequest'
    description 'HelpRequest Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :name, types.String, '', property: :name
    field :browser, types.String, '', property: :browser
    field :problem, types.String, '', property: :problem
    field :email, types.String, '', property: :email
    field :file, types.String, '', property: :file
    field :user, UserType, '', property: :user
    field :accountList, AccountListType, 'The parent account list', property: :account_list
    field :session, types.String, '', property: :session
    field :userPreferences, types.String, '', property: :user_preferences
    field :accountListSettings, types.String, '', property: :account_list_settings
    field :requestType, types.String, '', property: :request_type
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
