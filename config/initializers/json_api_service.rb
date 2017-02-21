require 'json_api_service'

JsonApiService.configure do |config|
  config.custom_references = {
    comments: 'ActivityComment',
    facebook_accounts: 'Person::FacebookAccount',
    google_accounts: 'Person::GoogleAccount',
    key_accounts: 'Person::KeyAccount',
    organization_accounts: 'Person::OrganizationAccount',
    user_options: 'User::Option'
  }

  config.ignored_foreign_keys = {
    account_lists: [
      :default_organization_id
    ],
    donations: [
      :remote_id
    ],
    exports_to_mail_chimp: [
      :mail_chimp_list_id
    ],
    facebook_accounts: [
      :remote_id
    ],
    google_accounts: [
      :remote_id
    ],
    key_accounts: [
      :relay_remote_id,
      :remote_id
    ],
    linkedin_accounts: [
      :remote_id
    ],
    mail_chimp_account: [
      :primary_list_id
    ],
    organization_accounts: [
      :remote_id
    ],
    twitter_accounts: [
      :remote_id
    ]
  }
end
