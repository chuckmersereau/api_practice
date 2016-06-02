def enable_http_logger
  # This will work in a prod_console even though the http_logger gem is in
  # the development group.
  require 'http_logger'
  HttpLogger.log_headers = true
  HttpLogger.logger = Logger.new(STDOUT)
  HttpLogger.collapse_body_limit = 10_000
  HttpLogger.ignore = [/newrelic\.com/]
end
