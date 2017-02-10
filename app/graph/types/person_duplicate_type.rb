module Types
  PersonDuplicateType = GraphQL::ObjectType.define do
    name 'PersonDuplicate'
    description 'A collection of two Person records that may be duplicates'

    field :id, !types.ID, 'The ID of the duplicate, used to mark a PersonDuplicate object as not a duplicate'
    field :person, !PersonType, 'The Person that we think should be the winner of a merge'
    field :duplicatePerson, !PersonType, 'The Person that we think should be the loser of a merge', property: :dup_person
    field :sharedContact, !ContactType, 'The Contact that both of these people are listed under', property: :shared_contact
  end
end
