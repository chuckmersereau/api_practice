source 'http://rubygems.org'
source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro'
end

gem 'rails', '~> 4.1.0'

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails',   '~> 5.0.1'
gem 'coffee-rails', '~> 4.0.1'

gem 'execjs' # , '~> 1.4.0'
# gem 'therubyracer', platforms: :ruby
# gem 'therubyrhino', '~> 2.0.2'

gem 'uglifier', '~> 2.4.0'
gem 'jquery-ui-rails', '~> 4.2.1'

gem 'angularjs-rails' # , '~> 1.2.16'
gem 'lodash-rails', '~> 3.5.0'
gem 'angular-ui-bootstrap-rails'
gem 'ngmin-rails'
gem 'momentjs-rails'
# gem 'rails_karma'
gem 'best_in_place', '~> 3.0.1'

# gem 'activeadmin'
gem 'active_model_serializers', '~> 0.8.1'
gem 'activerecord-import', '~> 0.7.0'
gem 'activesupport-json_encoder'
gem 'acts-as-taggable-on', '~> 3.0.0'
gem 'airbrake' # , '~> 3.1.6'
gem 'assignable_values', '~> 0.5.3'
gem 'carrierwave', git: 'https://github.com/carrierwaveuploader/carrierwave' # has cache err fix not release yet
gem 'charlock_holmes'
gem 'cloudinary'
gem 'country_select', git: 'http://github.com/CruGlobal/country_select.git' # My fork has the meta data for the fancy select
gem 'deadlock_retry', '~> 1.2.0'
gem 'devise', '~> 3.2.2'
gem 'display_case', '= 0.0.5'
gem 'email_reply_parser'
gem 'fb_graph', '~> 2.6.0'
gem 'fog', '~> 1.23.0'
gem 'font-awesome-rails'
gem 'foreigner'
gem 'gettext_i18n_rails', '~> 1.2.3'
gem 'gettext_i18n_rails_js', '~> 1.0.0'
gem 'gibberish', '~> 1.4.0'
gem 'gibbon', '~> 0.4.2'
gem 'google-api-client'
gem 'google_contacts_api', git: 'https://github.com/CruGlobal/google_contacts_api'
gem 'gmail', git: 'https://github.com/gmailgem/gmail.git'
gem 'gmaps4rails', '~> 2.1.2'
gem 'iniparse', '~> 1.1.6'
gem 'jquery-rails', '~> 3.0.4'
gem 'koala', '~> 1.9.0'
gem 'linkedin', '~> 0.3.7'
gem 'newrelic_rpm', '~> 3.7.1'
gem 'nokogiri', '~> 1.5.11'
gem 'oauth', git: 'http://github.com/CruGlobal/oauth-ruby'
gem 'oj', '~> 2.1.0'
gem 'omniauth-cas', '~> 1.0.2'
gem 'omniauth-facebook', '~> 1.6.0'
gem 'omniauth-google-oauth2' # , '~> 0.2.2'
gem 'omniauth-linkedin', '~> 0.1.0'
gem 'omniauth-prayer-letters'
gem 'omniauth-twitter', '~> 1.0.1'
gem 'paper_trail', '~> 3.0.0'
gem 'passenger'
gem 'pg', '~> 0.14.1'
gem 'rails_autolink', '~> 1.1.5'
gem 'rake'
gem 'redis-namespace'
gem 'redis-objects', '~> 0.6.1'
gem 'redis-rails'
gem 'rest-client', '~> 1.6.7'
gem 'retryable-rb', '~> 1.1.0'
gem 'rollout', '~> 2.0.0'
gem 'rollout_ui', git: 'https://github.com/CruGlobal/rollout_ui.git'
gem 'ruby-rtf'
gem 'savon', '~> 2.3.0'
gem 'secure_headers'
gem 'sidekiq-unique-jobs'
gem 'siebel_donations', '~> 1.0.5'
gem 'sinatra', require: nil
gem 'slim' # used for sidekiq web
gem 'twitter_cldr', '~> 2.4.0'
# gem 'typhoeus'
gem 'versionist', '~> 1.2.1'
gem 'virtus', '~> 0.5.4'
gem 'whenever', '~> 0.8.1'
gem 'wicked', '~> 1.0.2'
gem 'will_paginate', '~> 3.0.3'
gem 'global_phone', git: 'https://github.com/sstephenson/global_phone.git'
gem 'global_phone_dbgen'
# gem 'font_assets'
gem 'geocoder'
gem 'google_timezone'
gem 'email_validator'
gem 'peek'
gem 'peek-pg'
gem 'peek-git'
gem 'peek-redis'
gem 'peek-performance_bar'
gem 'peek-gc'
gem 'user_agent_decoder'

group :development do
  gem 'railroady'
  gem 'rails-footnotes' # , git: 'http://github.com/josevalim/rails-footnotes.git'
  gem 'bluepill'
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'sidekiq'
  gem 'rack-livereload'
  gem 'guard-livereload', '~> 2.4', require: false
  # only used for mo/po file generation in development, !do not load(:require=>false)! since it will eat 7mb ram
  gem 'gettext', '~> 3.1.6', require: false
  gem 'ruby_parser', require: false
end

group :development, :test do
  gem 'awesome_print'
  gem 'database_cleaner'
  gem 'spring-commands-rspec'
  gem 'rspec', '~> 3.3.0'
  gem 'rspec-rails', '~> 3.3.2'
  gem 'factory_girl_rails'
  gem 'guard-rubocop'
  gem 'guard-rspec'
  gem 'simplecov', require: false
  gem 'mailcatcher'
  gem 'fuubar'
  gem 'unicorn'
  gem 'zonebie'
  gem 'equivalent-xml'
end

group :test do
  gem 'mock_redis'
  gem 'webmock', '~> 1.21.0'
  gem 'rb-fsevent', require: false
  gem 'growl'
  gem 'capybara'
  gem 'poltergeist'
  gem 'resque_spec'
  gem 'emoji_spec', git: 'https://gist.github.com/6112257.git'
  gem 'rubocop', '~> 0.32.1'
  gem 'test_after_commit'
end

group :doc do
  gem 'sdoc', '~> 0.4.0'
end
