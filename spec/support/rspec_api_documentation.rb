RspecApiDocumentation.configure do |config|
  config.disable_dsl_status!
  config.format = ENV['DOC_FORMAT'] || :slate
  config.keep_source_order = false
  config.request_body_formatter = :json
  config.request_headers_to_include = %w(Authorization Content-Type)
  config.response_headers_to_include = %w(Content-Type)
  config.define_group :entities do |group_config|
    group_config.api_name = 'Entities'
    group_config.filter = :entities
  end
  config.define_group :account_lists do |group_config|
    group_config.api_name = 'Account Lists API'
    group_config.filter = :account_lists
  end
  config.define_group :appeals do |group_config|
    group_config.api_name = 'Appeals API'
    group_config.filter = :appeals
  end
  config.define_group :contacts do |group_config|
    group_config.api_name = 'Contacts API'
    group_config.filter = :contacts
  end
  config.define_group :people do |group_config|
    group_config.api_name = 'People API'
    group_config.filter = :people
  end
  config.define_group :tasks do |group_config|
    group_config.api_name = 'Tasks API'
    group_config.filter = :tasks
  end
  config.define_group :user do |group_config|
    group_config.api_name = 'User API'
    group_config.filter = :user
  end
  config.define_group :reports do |group_config|
    group_config.api_name = 'Reports API'
    group_config.filter = :reports
  end

  config.response_body_formatter = proc do |content_type, response_body|
    if content_type == 'application/json' || content_type.include?('application/vnd.api+json')
      JSON.pretty_generate(JSON.parse(response_body))
    else
      response_body
    end
  end
end
