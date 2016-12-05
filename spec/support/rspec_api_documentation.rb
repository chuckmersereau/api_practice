RspecApiDocumentation.configure do |config|
  config.disable_dsl_status!
  config.format = ENV['DOC_FORMAT'] || :slate
  config.keep_source_order = true
  config.request_body_formatter = :json
  config.request_headers_to_include = %w(Authorization Content-Type)
  config.response_headers_to_include = %w(Content-Type)
  config.define_group :entities do |group_config|
    group_config.filter = :entities
  end
  config.define_group :account_lists do |group_config|
    group_config.filter = :account_lists
  end
  config.define_group :appeals do |group_config|
    group_config.filter = :appeals
  end
  config.define_group :contacts do |group_config|
    group_config.filter = :contacts
  end
  config.define_group :tasks do |group_config|
    group_config.filter = :tasks
  end
  config.define_group :user do |group_config|
    group_config.filter = :user
  end
end
