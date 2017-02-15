module Types
  MailChimpAccountType = GraphQL::ObjectType.define do
    name 'MailChimpAccount'
    description 'A Mail Chimp Account object'

    field :id, !types.ID, 'The UUID of the Mail Chimp Account', property: :uuid
    field :accountList, AccountListType, 'The Account List for this Mail Chimp Account', property: :account_list
    field :active, types.Boolean, 'Whether or not this Mail Chimp Account is active'
    field :apiKey, !types.String, 'The Mail Chimp API Key for this Account', property: :api_key
    field :autoLogCampaigns, !types.Boolean, 'Whether or not to auto-log campaisng', property: :auto_log_campaigns
    field :createdAt, !types.String, 'The datetime in which the Mail Chimp Account was created', property: :created_at
    field :listsAvailableForNewsletters, types[MailChimpAccountListType], 'The lists for this Mail Chimp Account that are available for newsletters', property: :lists_available_for_newsletters_formatted
    field :listsLink, types.String, 'The link to find the lists for the Mail Chimp Account', property: :lists_link
    field :listsPresent, types.Boolean, 'Whether or not there are lists for this Mail Chimp Account' do
      resolve -> (obj, args, ctx) {
        obj.lists.present?
      }
    end
    field :primaryListId, types.String, 'The id of the Primary List for this account', property: :primary_list_id
    field :primaryListName, types.String, 'The name of the Primary List for this account', property: :primary_list_name
    field :syncAllActiveContacts, types.Boolean, 'Whether or not to sync all active contentx', property: :sync_all_active_contacts
    field :valid, types.Boolean, 'Whether or not the Mail Chimp Account is valid', property: :valid?
    field :validateKey, types.String, 'Whether or not to validate to validate the key for this Mail Chimp Account', property: :validate_key
    field :validationError, types.String, 'An error message returned in the event of a validation problem', property: :validation_error
    field :updatedAt, !types.String, 'The datetime in which the Mail Chimp Account was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Mail Chimp Account was last updated in the database', property: :updated_at
  end
end
