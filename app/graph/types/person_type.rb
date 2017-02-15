module Types
  PersonType = GraphQL::ObjectType.define do
    name 'Person'
    description 'A Person object'

    connection :emailAddresses, -> { EmailAddressType.connection_type }, 'The Email Addresses associated with this Person', property: :email_addresses
    connection :facebookAccounts, -> { FacebookAccountType.connection_type }, 'The Facebook Accounts associated with this Person', property: :facebook_accounts
    connection :familyRelationships, -> { FamilyRelationshipType.connection_type }, 'The Familial Relationships of this Person', property: :family_relationships
    connection :linkedinAccounts, -> { LinkedinAccountType.connection_type }, 'The LinkedIn Accounts associated with this Person', property: :linkedin_accounts
    connection :phoneNumbers, -> { PhoneNumberType.connection_type }, 'The Phone Numbers associated with this Person', property: :phone_numbers
    connection :twitterAccounts, -> { TwitterAccountType.connection_type }, 'The Twitter Accounts associated with this Person', property: :twitter_accounts
    connection :websites, -> { WebsiteType.connection_type }, 'The Websites associated with this Person'

    field :id, !types.ID, 'The UUID of the person', property: :uuid
    field :anniversaryDay, types.String, 'The Anniversary Day of this Person', property: :anniversary_day
    field :anniversaryMonth, types.String, 'The Anniversary Month of this Person', property: :anniversary_month
    field :anniversaryYear, types.String, 'The Anniversary Year this Person', property: :anniversary_year
    field :avatar, types.String, 'The Avatar of this Person' do
      resolve -> (obj, args, ctx) { PersonSerializer.new(obj).avatar }
    end
    field :birthdayDay, types.String, 'The Birthday Day of this Person', property: :birthday_day
    field :birthdayMonth, types.String, 'The Birthday Month this Person', property: :birthday_month
    field :birthdayYear, types.String, 'The Birthday Year this Person', property: :birthday_year
    field :createdAt, !types.String, 'The timestamp the Person was created', property: :created_at
    field :deceased, types.String, 'Whether or not this Person is deceased'
    field :firstName, !types.String, 'The first name of the Person', property: :first_name
    field :gender, types.String, 'The gender of this Person'
    field :lastName, types.String, 'The last name for this Person', property: :last_name
    field :maritalStatus, types.String, 'The last name for this Person', property: :marital_status
    # field :masterPersonId
    field :middleName, types.String, 'The middle name for this Person', property: :middle_name
    field :suffix, types.String, 'The suffix for this Person (Jr., III, etc.)'
    field :title, types.String, 'The title for this Person (Mr., Mrs., etc.)'
    field :updatedAt, !types.String, 'The timestamp of the last time this Person was updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp of the last time this Person was updated', property: :updated_at
  end
end
