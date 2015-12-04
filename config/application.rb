require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(PhusionPassenger)
  require 'phusion_passenger/rack/out_of_band_gc'
  require 'phusion_passenger/public_api'
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mpdx
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/app/concerns #{config.root}/app/roles #{config.root}/app/validators #{config.root}/app/errors #{config.root}/lib)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.active_record.schema_format = :sql

    config.assets.paths << "#{Rails.root}/app/assets/fonts"

    config.exceptions_app = self.routes

    config.log_formatter = ::Logger::Formatter.new
    config.middleware.swap Rails::Rack::Logger, Silencer::Logger, config.log_tags, :silence => ['/monitors/lb']
  end
end

