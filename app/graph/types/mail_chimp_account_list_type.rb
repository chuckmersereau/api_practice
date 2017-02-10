module Types
  MailChimpAccountListType = GraphQL::ObjectType.define do
    name 'MailChimpAccountList'
    description 'A List from a Mail Chipm Account object'

    field :id, !types.String, 'The ID of the Mail Chimp Account List', hash_key: :id
    field :name, !types.String, 'The name of the Mail Chimp Account List', hash_key: :name
  end
end
