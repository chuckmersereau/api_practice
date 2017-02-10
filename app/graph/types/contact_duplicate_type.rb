module Types
  ContactDuplicateType = GraphQL::ObjectType.define do
    name 'ContactDuplicate'
    description 'A collection of two Contact records that may be duplicates'

    field :id, !types.ID, 'The ID of the duplicate, used to mark a ContactDuplicate object as not a duplicate'
    field :contacts, !types[!ContactType], 'The Contacts that are believed to be duplicates'
  end
end
