module Types
  FamilyRelationshipType = GraphQL::ObjectType.define do
    name 'FamilyRelationship'
    description 'A Family Relationship object'

    field :id, !types.ID, 'The ID for this Family Relationship', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the Family Relationship was created', property: :created_at
    field :person, PersonType, "The Person who is the indirect object in the sentence \"Brynn is Will's wife\""
    field :relatedPerson, PersonType, "The Person who is the direct object in the setence \"Brynn is Will's ife\"", property: :related_person
    field :relationship, !types.String, 'The type of Family Relationship'
    field :updatedAt, !types.String, 'The timestamp that the Family Relationship was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the Family Relationship was last updated', property: :updated_at
  end
end
