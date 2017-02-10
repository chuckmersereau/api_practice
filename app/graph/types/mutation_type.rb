module Types
  MutationType = GraphQL::ObjectType.define do
    name 'Mutation'
    description 'The mutation root for this schema'

    field :contactCreate, field: Mutations::ContactCreateMutation.field
    field :contactUpdate, field: Mutations::ContactUpdateMutation.field
  end
end
