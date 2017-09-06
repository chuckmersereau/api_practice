Rails.application.configure do
  # Make it easy to turn on http logger when you want it
  if ENV['HTTP_LOGGER']
    HttpLogger.log_headers = true
    HttpLogger.logger = Logger.new(STDOUT)
    HttpLogger.collapse_body_limit = 10_000
    HttpLogger.ignore = [/newrelic\.com/]
  else
    HttpLogger.logger = Logger.new('/dev/null')
  end

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Prefer responses to be sent in JSON, so disable Rails error reports by considering requests as remote.
  # (consider reverting this when upgrading to Rails 5)
  config.consider_all_requests_local       = false

  # Disable caching.
  config.action_controller.perform_caching = false
  # config.action_controller.perform_caching = true
  config.i18n.fallbacks = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  config.assets.digest = false

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.assets.logger = false

  config.assets.prefix = '/dev-assets'

  # The ngrok utility to tunnel connections to localhost is useful for testing
  # the MailChimp webhooks feature
  config.action_mailer.default_url_options = {
    host: ENV['DEV_NGROK_HOST'].present? ? ENV['DEV_NGROK_HOST'] : 'localhost:3000',
    protocol: 'http'
  }

  config.debug_exception_response_format = :default

  config.action_mailer.asset_host = 'http://localhost:3000'

  config.action_mailer.delivery_method = :letter_opener

  config.action_mailer.preview_path = Rails.root.join('spec', 'mailers', 'previews')

  Rails.application.routes.default_url_options[:host] = config.action_mailer.default_url_options[:host]
  Rails.application.routes.default_url_options[:protocol] = config.action_mailer.default_url_options[:protocol]
end
