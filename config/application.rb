require File.expand_path('../boot', __FILE__)

require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mpdx
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(
      #{config.root}/app/concerns
      #{config.root}/app/errors
      #{config.root}/app/preloaders
      #{config.root}/app/roles
      #{config.root}/app/validators
      #{config.root}/lib
    )

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    config.active_record.schema_format = :sql
    config.active_record.cache_timestamp_format = :nsec

    config.active_job.queue_adapter = :sidekiq
    config.active_record.raise_in_transactional_callbacks = true

    config.log_formatter = ::Logger::Formatter.new

    config.assets.enabled = false
    config.api_only = true

    config.generators do |g|
      g.assets false
    end

    config.middleware.insert_before 0, 'Rack::MethodOverride'

    config.middleware.insert_before 'ActionDispatch::ShowExceptions', 'BatchRequestHandler::Middleware',
      endpoint: '/api/v2/batch',
      instruments: [
        'BatchRequestHandler::Instruments::Logging',
        'BatchRequestHandler::Instruments::RequestValidator',
        'BatchRequestHandler::Instruments::RequestLimiter',
        'BatchRequestHandler::Instruments::AbortOnError'
      ]

    config.middleware.insert_before 'BatchRequestHandler::Middleware', 'JsonWebToken::Middleware'

    config.after_initialize do |app|
      app.routes.append{ match '*a', :to => 'api/error#not_found', via: [:get, :post] } unless config.consider_all_requests_local
    end
  end
end
