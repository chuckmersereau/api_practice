RESOURCE_TYPE_TO_DB_TYPE = {
    comments: 'activity_comments',
    facebook_accounts: 'person_facebook_accounts',
    google_accounts: 'person_google_accounts',
    key_accounts: 'person_relay_accounts', # This was added because Key accounts are stored as Relay accounts in the db
    linkedin_accounts: 'person_linkedin_accounts',
    organization_accounts: 'person_organization_accounts',
    referrers: 'contacts',
    relay_accounts: 'person_relay_accounts',
    tasks: 'activities',
    user_options: 'person_options',
    users: 'people',
    websites: 'person_websites'
}.freeze