module Types
  MasterPersonType = GraphQL::ObjectType.define do
    name 'MasterPerson'
    description 'A Master Person object'

    connection :people, -> { PersonType.connection_type }, 'The people belonging to this Master Person'

    field :id, !types.ID, 'The UUID of the Master Person', property: :uuid
    field :createdAt, !types.String, 'The timestamp the Master Person was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this Master Person was updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp of the last time this Master Person was updated', property: :updated_at
  end
end
