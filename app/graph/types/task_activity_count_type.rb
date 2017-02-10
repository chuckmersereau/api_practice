module Types
  TaskActivityCountType = GraphQL::ObjectType.define do
    name 'TaskActivityCount'
    description 'Task Activities Count'

    field :label, !types.String, 'Count Label'
    field :count, !types.Int, 'Count'
  end
end
