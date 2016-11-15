require File.expand_path('../boot', __FILE__)

require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'

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
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    config.active_record.schema_format = :sql
    config.active_record.cache_timestamp_format = :nsec

    config.log_formatter = ::Logger::Formatter.new

    config.assets.enabled = false
    config.api_only = true

    config.generators do |g|
      g.assets false
    end
  end
end
