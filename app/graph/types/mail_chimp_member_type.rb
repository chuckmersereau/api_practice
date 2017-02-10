module Types
  MailChimpMemberType = GraphQL::ObjectType.define do
    name 'MailChimpMember'
    description 'MailChimpMember Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :mailChimpAccountId, !types.Int, '', property: :mail_chimp_account_id
    field :listId, !types.String, '', property: :list_id
    field :email, !types.String, '', property: :email
    field :status, types.String, '', property: :status
    field :greeting, types.String, '', property: :greeting
    field :firstName, types.String, '', property: :first_name
    field :lastName, types.String, '', property: :last_name
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :contactLocale, types.String, '', property: :contact_locale
    field :tags, types.String, '[]', property: :tags
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
