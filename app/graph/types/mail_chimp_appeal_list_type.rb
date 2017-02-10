module Types
  MailChimpAppealListType = GraphQL::ObjectType.define do
    name 'MailChimpAppealList'
    description 'MailChimpAppealList Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :mailChimpAccountId, !types.Int, '', property: :mail_chimp_account_id
    field :appealListId, !types.String, '', property: :appeal_list_id
    field :appealId, !types.Int, '', property: :appeal_id
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
