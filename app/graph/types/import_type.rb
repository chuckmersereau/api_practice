module Types
  ImportType = GraphQL::ObjectType.define do
    name 'Import'
    description 'An Import Object'

    field :id, !types.ID, 'The UUID', property: :uuid
    field :accountList, AccountListType, 'The parent account list', property: :account_list
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :file, types.String, 'The URL of the file for the Import' do
      resolve -> (obj, arg, ctx) do
        obj.file&.url
      end
    end
    field :groupTags, JsonType, 'TODO', property: :group_tags
    field :groups, types[types.String], 'TODO'
    field :importByGroup, types.Boolean, 'TODO', property: :import_by_group
    field :override, types.Boolean, 'TODO'
    field :source, types.String, 'The type of file that was imported, ex: "csv"'
    field :sourceAccountId, types.Int, 'TODO', property: :source_account_id
    field :tags, types.String, 'TODO'
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :user, UserType, 'The User that the Import belongs to'
  end
end
