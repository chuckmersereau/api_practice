module Types
  UserPreferencesType = GraphQL::ObjectType.define do
    name 'UserPreferences'
    description 'A set of preferences for a user'

    field :admin, types.Boolean, 'Whether or not the User is an admin', hash_key: :admin
    field :contactsFilter, JsonType, "The User's preferred Contact filter", hash_key: :contacts_filter
    field :contactsViewOptions, JsonType, "The User's preferred view options for contacts", hash_key: :contacts_view_options
    field :defaultAccountList, AccountListType, "The User's default Account List" do
      resolve -> (obj, args, ctx) {
        AccountList.find(obj[:default_account_list]) if obj[:default_account_list]
      }
    end
    field :developer, types.Boolean, 'Whether or not the User is a developer', hash_key: :developer
    field :locale, types.String, "The User's locale", hash_key: :locale
    field :setup, types.String, "TODO The User's setup?", hash_key: :setup
    field :tabOrders, JsonType, "The User's preferred tab order", hash_key: :tab_orders
    field :tasksFilter, JsonType, "The User's preferred Tasks filter", hash_key: :tasks_filter
    field :timeZone, types.String, "The User's preferred time zone", hash_key: :time_zone
  end
end
