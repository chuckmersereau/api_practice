module Types
  CommentType = GraphQL::ObjectType.define do
    name 'Comment'
    description 'Comment for a Task'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :task, !TaskType, 'Task the author is commenting on', property: :activity
    field :author, UserType, 'Author of the comment', property: :person
    field :body, types.String, 'Content of comment', property: :body
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
