RspecApiDocumentation.configure do |config|
  config.format = ENV['DOC_FORMAT'] || :json
  config.keep_source_order = true
  config.response_headers_to_include = %w(Content-Type)
  config.request_headers_to_include = %w(Authorization Content-Type)
  config.disable_dsl_status!
end
