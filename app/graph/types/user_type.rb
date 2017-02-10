module Types
  UserType = GraphQL::ObjectType.define do
    name 'User'
    description 'A user object, come on, we all know what a user is'

    connection :accountLists, -> { AccountListType.connection_type }, 'The associated Account Lists for this User', property: :account_lists
    connection :contacts, -> { ContactConnectionWithAnalyticsType }, 'The associated Contacts across all Account Lists for this User'
    connection :tasks, -> { TaskConnectionWithAnalyticsType }, 'The associated Tasks across all Account Lists for this User'
    connection :emailAddresses, -> { EmailAddressType.connection_type }, 'The associated Email Addresses for this user', property: :email_addresses

    field :id, !types.ID, 'The UUID of the User', property: :uuid
    field :createdAt, !types.String, 'The timestamp the User was created', property: :created_at
    field :firstName, !types.String, 'The first name of the User', property: :first_name
    field :lastName, types.String, 'The last name of the User', property: :last_name
    field :masterPerson, PersonType, 'TODO', property: :master_person
    field :preferences, UserPreferencesType, 'The preferences for the User'
    field :updatedAt, !types.String, 'The timestamp of the last time this User was updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp of the last time this User was updated', property: :updated_at
  end
end
