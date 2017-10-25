API_DOC_LEGEND = {
  entities: %i(
    account_lists
    appeals
    background_batches
    contacts
    constants
    people
    tasks
    user
  ),
  account_lists_api: %i(
    analytics
    chalkline_mail
    designation_accounts
    donations
    donor_accounts
    imports
    invites
    mailchimp_accounts
    merges
    notification_preferences
    notifications
    prayer_letters_accounts
    users
  ),
  appeals_api: %i(
    contacts
  ),
  contacts_api: %i(
    addresses
    analytics
    duplicates
    exports
    filter
    merges
    tags
  ),
  people_api: %i(
    duplicates
    email_addresses
    facebook_accounts
    linkedin_accounts
    merges
    phones
    relationships
    twitter_accounts
    websites
  ),
  tasks_api: %i(
    analytics
    comments
    filter
    tags
  ),
  user_api: %i(
    authenticate
    google_accounts
    key_accounts
    options
    organization_accounts
  ),
  reports_api: %i(
    donation_summaries
    monthly_totals
    goal_progress
    monthly_giving
  )
}.freeze

RspecApiDocumentation.configure do |config|
  config.disable_dsl_status!
  config.format = ENV['DOC_FORMAT'] || :slate
  config.keep_source_order = false
  config.request_body_formatter = :json
  config.request_headers_to_include = %w(Authorization Content-Type)
  config.response_headers_to_include = %w(Content-Type)

  API_DOC_LEGEND.each do |groups_parent, group_names|
    config.define_group groups_parent do |group_config|
      group_config.api_name = groups_parent.to_s.titleize
      group_config.filter   = groups_parent
    end

    group_names.each do |group_name|
      group_ref = "#{groups_parent}/#{group_name}"
      api_name  = group_name.to_s.titleize
      filter    = "#{groups_parent}_#{group_name}".to_sym

      config.define_group group_ref do |group_config|
        group_config.api_name = api_name
        group_config.filter   = filter
      end
    end
  end

  config.response_body_formatter = proc do |content_type, response_body|
    if content_type == 'application/json' || content_type.include?('application/vnd.api+json')
      JSON.pretty_generate(JSON.parse(response_body))
    else
      response_body
    end
  end
end
