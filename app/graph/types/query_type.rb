module Types
  QueryType = GraphQL::ObjectType.define do
    name 'Query'
    description 'The query root for this schema'

    field :accountList, AccountListType, 'Fetch an Account List by ID', field: Fields::FetchField.build(type: AccountListType, model: AccountList)
    field :appeal, AppealType, 'Fetch an Appeal by ID', field: Fields::FetchField.build(type: AppealType, model: Appeal)

    field :constants do
      type !ConstantsLookupType
      description 'The Constants used in the application'

      resolve -> (obj, args, ctx) do
        ConstantListSerializer.new(ConstantList.new)
      end
    end

    field :contact, ContactType, 'Fetch a Contact by ID', field: Fields::FetchField.build(type: ContactType, model: Contact)

    field :me do
      type !UserType
      description 'The currently logged in user'

      resolve -> (obj, args, ctx) do
        ctx[:current_user]
      end
    end

    field :task, TaskType, 'Fetch a Task by ID', field: Fields::FetchField.build(type: TaskType, model: Task)
    field :user, UserType, 'Fetch a user by ID', field: Fields::FetchField.build(type: UserType, model: User)
  end
end
