module Types
  TagType = GraphQL::ObjectType.define do
    name 'Tag'
    description 'A Tag Object'

    field :id, !types.ID, 'The UUID of the Tag', property: :uuid
    field :name, !types.String, 'The name of the Tag', property: :name
  end
end
