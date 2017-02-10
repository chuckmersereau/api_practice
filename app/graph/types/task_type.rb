module Types
  TaskType = GraphQL::ObjectType.define do
    name 'Task'
    description 'Task Object'
    connection :comments, -> { CommentType.connection_type }, 'The Comments associated with this Task', property: :activity_comments
    connection :contacts, -> { ContactType.connection_type }, 'The Contacts associated with this Task', property: :activity_contacts
    connection :tags, -> { TagType.connection_type }, 'The Tags associated with this Task', property: :tags

    field :_appId, !types.ID, 'The application ID', property: :id
    field :accountList, AccountListType, 'The parent account list', property: :account_list
    field :starred, !types.Boolean, 'Is task starred DEFAULT false', property: :starred
    field :location, types.String, 'The place the task should take place', property: :location
    field :subject, types.String, 'The objective of the task', property: :subject
    field :startAt, types.String, 'the time the task should be started', property: :start_at
    field :endAt, types.String, 'the time the task should be completed', property: :end_at
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :completed, !types.Boolean, 'The completed state of this task DEFAULT false', property: :completed
    field :activityType, types.String, 'The type of task this is', property: :activity_type
    field :result, types.String, 'The outcome of the completion of this task', property: :result
    field :completedAt, types.String, 'timestamp without timezone', property: :completed_at
    field :noDate, types.Boolean, 'does this task require a startAt? DEFAULT false', property: :no_date
    field :notificationType, types.Int, 'The type of notification to send to the user', property: :notification_type
    field :notificationTimeBefore, types.Int, 'The amount of time before startAt to send the user a notification', property: :notification_time_before
    field :notificationTimeUnit, types.Int, 'The unit of time n"otificationTimeBefore" represents', property: :notification_time_unit
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
