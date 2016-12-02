RspecApiDocumentation.configure do |config|
  config.disable_dsl_status!
  config.format = ENV['DOC_FORMAT'] || :slate
  config.keep_source_order = true
  config.request_body_formatter = :json
  config.request_headers_to_include = %w(Authorization Content-Type)
  config.response_headers_to_include = %w(Content-Type)
end
