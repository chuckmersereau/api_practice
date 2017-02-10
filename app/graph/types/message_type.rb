module Types
  MessageType = GraphQL::ObjectType.define do
    name 'Message'
    description 'Message Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :fromId, types.Int, '', property: :from_id
    field :toId, types.Int, '', property: :to_id
    field :subject, types.String, '', property: :subject
    field :body, types.String, '', property: :body
    field :sentAt, types.String, 'timestamp without timezone', property: :sent_at
    field :source, types.String, '', property: :source
    field :remoteId, types.String, '', property: :remote_id
    field :contact, ContactType, '', property: :contact
    field :accountList, AccountListType, 'The parent account list', property: :account_list
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
