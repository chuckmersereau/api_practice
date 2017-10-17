source 'https://rubygems.org'
source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro', '~> 3.5.0'
end

gem 'auth', path: 'engines/auth'
gem 'active_model_serializers', '= 0.10.3'
# active_model_serializers is locked to '0.10.3' because future versions no longer support the use
# of Json Api Spec serializer for resources that do not have an id. That was necessary, because we
# have several serializers (eg. Reports and Analytics Serializers) that represent resources without an id.
gem 'activerecord-import', '~> 0.16.1'
gem 'activesupport-json_encoder', '~> 1.1.0'
gem 'acts-as-taggable-on', '~> 4.0.0'
gem 'assignable_values', '~> 0.11.2'
gem 'attributes_history', '~> 0.0.3'
gem 'axlsx', '= 2.0.1'
gem 'axlsx_rails', '~> 0.5.0'
gem 'carrierwave', '~> 0.11.2'
gem 'charlock_holmes', '~> 0.7.4'
gem 'cloudinary', '~> 1.8.1'
gem 'country_select', git: 'https://github.com/CruGlobal/country_select.git' # My fork has the meta data for the fancy select
gem 'ddtrace', '~> 0.7.2'
gem 'deadlock_retry', '~> 1.2.0'
gem 'devise', '~> 4.2.1'
gem 'display_case', '= 0.0.5'
gem 'dotenv-rails', '~> 2.1.1'
gem 'email_reply_parser', '~> 0.5.9'
gem 'email_validator', '~> 1.6.0'
gem 'fb_graph', '~> 2.6.0'
gem 'fog', '~> 1.36.0'
gem 'foreigner', '~> 1.7.4'
gem 'geocoder', '~> 1.4.0'
gem 'gettext_i18n_rails', '~> 1.7.2'
gem 'gibberish', '~> 1.4.0'
gem 'gibbon', '~> 2.2.4'
gem 'gmail', git: 'https://github.com/gmailgem/gmail.git', ref: '4f78039e9821340a24ad3d840180d2ec6c6e0115'
gem 'google-api-client', '~> 0.13.1'
gem 'google_contacts_api', git: 'https://github.com/CruGlobal/google_contacts_api'
gem 'google_timezone', '~> 0.0.5'
gem 'graphql', '~> 1.4.2'
gem 'iniparse', '~> 1.1.6'
gem 'inky-rb', '~> 1.3.7', require: 'inky'
gem 'jwt', '~> 1.5.6'
gem 'kaminari', '~> 0.16.3'
gem 'koala', '~> 1.9.0'
gem 'linkedin', '~> 0.3.7'
gem 'mail', '~> 2.6.6'
gem 'newrelic_rpm', '< 5'
gem 'oauth', git: 'https://github.com/CruGlobal/oauth-ruby'
gem 'oj', '~> 2.18.5'
gem 'pg', '~> 0.20.0'
gem 'phonelib', '~> 0.5.4'
gem 'premailer-rails', '~> 1.9.7'
gem 'puma', '~> 3.6.0'
gem 'pundit', '~> 1.1.0'
gem 'rack-cors', '~> 0.4.0', require: 'rack/cors'
gem 'rails', '~> 4.2.0'
gem 'rails-api', '~> 0.4.0'
gem 'rails_autolink', '~> 1.1.5'
gem 'rake', '~> 10.5.0'
gem 'redis-namespace', '~> 1.5.3'
gem 'redis-objects', '~> 0.6.1'
gem 'redis-rails', '~> 5.0.1'
gem 'responders', '~> 2.4.0'
gem 'rest-client', '~> 2.0.2'
gem 'retryable-rb', '~> 1.1.0'
gem 'rollbar', '~> 2.8.3'
gem 'rollout', '~> 2.0.0'
gem 'ruby-rtf', '~> 0.0.1'
gem 'rubyzip', '= 1.0.0'
gem 'sidekiq-cron', '~> 0.4.4'
gem 'sidekiq-unique-jobs', '~> 5.0.8'
gem 'siebel_donations', '1.0.7'
gem 'sinatra', '~> 1.4.7', require: nil
gem 'slim', '~> 3.0.7' # used for sidekiq web
gem 'snail', '~> 2.2.1'
gem 'syslog-logger', '~> 1.6.8'
gem 'twitter_cldr', '~> 4.4.0'
gem 'user_agent_decoder', '~> 0.0.9'
gem 'uglifier'
gem 'versionist', '~> 1.2.1'
gem 'virtus', '~> 1.0.5'
gem 'nameable', '~> 1.1.3'

group :development do
  gem 'bluepill', '~> 0.1.2'
  gem 'http_logger', '~> 0.5.1'
  gem 'letter_opener', '~> 1.4.1'
  gem 'railroady', '~> 1.5.2'
  gem 'rails-footnotes', '~> 4.1.8'
end

group :development, :test do
  gem 'awesome_print', '~> 1.7.0'
  gem 'database_cleaner', '~> 1.5.3'
  gem 'equivalent-xml', '~> 0.6.0'
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'gettext', '~> 3.1.6', require: false, group: :development
  gem 'guard-brakeman'
  gem 'guard-bundler'
  gem 'guard-bundler-audit', git: 'https://github.com/christianhellsten/guard-bundler-audit.git'
  gem 'guard-puma'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-sidekiq'
  gem 'indefinite_article' # used for documentation generation
  gem 'parallel_tests', '~> 2.10.0'
  gem 'pry-byebug', '~> 3.4.0'
  gem 'pry-rails', '~> 0.3.4'
  gem 'rails-erd', '~> 1.5.0'
  gem 'rspec', '~> 3.4'
  gem 'rspec-rails', '~> 3.4'
  gem 'rspec_api_documentation',
      git: 'https://github.com/CruGlobal/rspec_api_documentation',
      ref: '5e766726cfd9fe8e16bfcfc58e013b7b549d5945'
  gem 'ruby_parser', require: false, group: :development
  gem 'simplecov', '~> 0.14.1', require: false
  gem 'simplecov-lcov', '~> 0.5.0', require: false
  gem 'spring', '~> 1.7.1' # only used for mo/po file generation in development, !do not load(:require=>false)! since it will eat 7mb ram
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'zonebie', '~> 0.6.1'
end

group :test do
  gem 'ammeter', '~> 1.1.4' # for testing generators
  gem 'coveralls', '~> 0.8.21', require: false
  gem 'codecov', require: false
  gem 'faker', '~> 1.6.6'
  gem 'growl', '~> 1.0.3'
  gem 'mock_redis', '~> 0.17.0'
  gem 'rb-fsevent', require: false
  gem 'roo', '~> 1.13.2'
  gem 'rspec-retry', '~> 0.5.5'
  gem 'rubocop', '= 0.42', require: false
  gem 'shoulda-matchers', '~> 3.1.1'
  gem 'test_after_commit'
  gem 'webmock', '< 3'
end

group :doc do
  gem 'sdoc', '~> 0.4.0'
end

# add this at the end so it plays nice with pry
gem 'marco-polo', '~> 1.2.1'
