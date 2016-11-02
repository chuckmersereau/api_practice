source 'http://rubygems.org'
source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro', '~> 3.4.0'
end

gem 'rails', '~> 4.1.8'
gem 'rails-api', '~> 0.4.0'
gem 'syslog-logger', '~> 1.6.8'

gem 'active_model_serializers', '~> 0.8.1'
gem 'activerecord-import', '~> 0.16.1'
gem 'activesupport-json_encoder', '~> 1.1.0'
gem 'acts-as-taggable-on', '~> 3.0.0'
gem 'rollbar', '~> 2.8.3'
gem 'assignable_values', '~> 0.11.2'
gem 'attributes_history', '~> 0.0.3'
gem 'carrierwave', '~> 0.11.2'
gem 'charlock_holmes', '~> 0.7.3'
gem 'cloudinary', '~> 1.2.3'
gem 'deadlock_retry', '~> 1.2.0'
gem 'devise', '~> 3.4.0'
gem 'display_case', '= 0.0.5'
gem 'email_reply_parser', '~> 0.5.9'
gem 'fb_graph', '~> 2.6.0'
gem 'fog', '~> 1.36.0'
gem 'pundit', '~> 1.1.0'
gem 'snail', '~> 2.2.1'
gem 'jwt', '~> 1.5.6'

gem 'foreigner', '~> 1.7.4'
gem 'gettext_i18n_rails', '~> 1.7.2'
gem 'gibberish', '~> 1.4.0'
gem 'gibbon', '~> 2.2.4'
gem 'google-api-client', '~> 0.7.1'
gem 'google_contacts_api', git: 'https://github.com/CruGlobal/google_contacts_api'
gem 'gmail', git: 'https://github.com/cynektix/gmail.git', branch: 'fix-to-imap-date'
gem 'country_select', git: 'http://github.com/CruGlobal/country_select.git' # My fork has the meta data for the fancy select

gem 'iniparse', '~> 1.1.6'
gem 'koala', '~> 1.9.0'
gem 'linkedin', '~> 0.3.7'
gem 'newrelic_rpm', '~> 3.7.1'
gem 'kaminari', '~> 0.16.3'
gem 'oauth', git: 'http://github.com/CruGlobal/oauth-ruby'
gem 'oj', '~> 2.14.0'
gem 'omniauth-cas', '~> 1.1.1'
gem 'omniauth-facebook', '~> 1.6.0'
gem 'omniauth-google-oauth2', '~> 0.2.6'
gem 'omniauth-linkedin', '~> 0.1.0'
gem 'omniauth-pls', '~> 0.0.2'
gem 'omniauth-prayer-letters'
gem 'omniauth-twitter', '~> 1.0.1'
gem 'paper_trail', '~> 4.0.1'
gem 'pg', '~> 0.18.2'
gem 'rails_autolink', '~> 1.1.5'
gem 'rake', '~> 10.5.0'
gem 'redis-namespace', '~> 1.5.2'
gem 'redis-objects', '~> 0.6.1'
gem 'redis-rails', '~> 5.0.1'
gem 'rest-client', '~> 1.6.7'
gem 'retryable-rb', '~> 1.1.0'
gem 'rollout', '~> 2.0.0'
gem 'ruby-rtf', '~> 0.0.1'
gem 'savon', '~> 2.3.0'
gem 'sidekiq-unique-jobs', git: 'https://github.com/mhenrixon/sidekiq-unique-jobs'
gem 'sidekiq-cron', '~> 0.4.4'
gem 'siebel_donations', '~> 1.0.6'
gem 'sinatra', '~> 1.4.7', require: nil
gem 'slim', '~> 3.0.7' # used for sidekiq web
gem 'twitter_cldr', '~> 2.4.0'
gem 'versionist', '~> 1.2.1'
gem 'virtus', '~> 1.0.5'
gem 'geocoder', '~> 1.4.0'
gem 'google_timezone', '~> 0.0.5'
gem 'email_validator', '~> 1.6.0'
gem 'user_agent_decoder', '~> 0.0.9'
gem 'puma', '~> 3.6.0'
gem 'phonelib', '~> 0.5.4'
gem 'silencer', '~> 0.6.0'
gem 'rubyzip', '= 1.0.0'
gem 'dotenv-rails', '~> 2.1.1'
gem 'apitome', '~> 0.1.0'

group :development do
  gem 'railroady', '~> 1.5.2'
  gem 'rails-footnotes', '~> 4.1.8'
  gem 'bluepill', '~> 0.1.2'
  gem 'http_logger', '~> 0.5.1'
  # only used for mo/po file generation in development, !do not load(:require=>false)! since it will eat 7mb ram
end

group :development, :test do
  gem 'parallel_tests', '~> 2.10.0'
  gem 'awesome_print', '~> 1.7.0'
  gem 'database_cleaner', '~> 1.5.3'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'rspec', '~> 3.4'
  gem 'rspec-rails', '~> 3.4'
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'guard-rubocop', '~> 1.2.0'
  gem 'guard-rspec', '~> 4.7.3'
  gem 'simplecov', '~> 0.12.0', require: false
  gem 'simplecov-lcov', '~> 0.5.0', require: false
  gem 'spring', '~> 1.7.1'
  # only used for mo/po file generation in development, !do not load(:require=>false)! since it will eat 7mb ram
  gem 'gettext', '~> 3.1.6', require: false, group: :development
  gem 'ruby_parser', require: false, group: :development
  gem 'zonebie', '~> 0.6.1'
  gem 'equivalent-xml', '~> 0.6.0'
  gem 'pry-byebug', '~> 3.4.0'
  gem 'pry-rails', '~> 0.3.4'
  gem 'rails-erd'
  gem 'rspec_api_documentation', '~> 4.8.0'
end

group :test do
  gem 'mock_redis', '~> 0.17.0'
  gem 'webmock', '~> 1.21.0'
  gem 'rb-fsevent', require: false
  gem 'growl', '~> 1.0.3'
  gem 'rubocop', '= 0.39', require: false
  gem 'test_after_commit'
  gem 'coveralls', '~> 0.8.15', require: false
  gem 'faker', '~> 1.6.6'
end

group :doc do
  gem 'sdoc', '~> 0.4.0'
end

# add this at the end so it plays nice with pry
gem 'marco-polo', '~> 1.2.1'
