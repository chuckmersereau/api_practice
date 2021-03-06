if ENV['CI']
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter 'dev/'
    add_filter 'vendor/'
  end

  if ENV['COVERALLS_REPO_TOKEN']
    require 'coveralls'
    Coveralls.wear_merged!('rails')
  end
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)

# Prevent database truncation if the environment is production
abort('The Rails environment is not running in test mode!') unless Rails.env.test?

require 'spec_helper'
require 'rspec/rails'
require 'rspec/matchers'
require 'rspec/retry'
require 'equivalent-xml'
require 'ammeter/init'
require 'shoulda/matchers'
require 'documentation_helper'

# Add additional requires below this line. Rails is not loaded until this point!
require 'global_registry_bindings/testing'
GlobalRegistry::Bindings::Testing.skip_workers!

# Include Sidekiq testing helpers and fake sidekiq
require 'sidekiq/testing'
Sidekiq::Testing.fake!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Reset seed each time this file is loaded, so that spring won't cache seed
  # To run a spec with a specific seed, use --order=rand:[seed]
  config.seed = srand % 0xFFFF unless ARGV.any? { |arg| arg =~ /seed/ }
  config.order = :random

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Exclude gems from spec backtraces, except a few directly related to our app
  config.filter_gems_from_backtrace(
    *(Gem::Specification.map(&:name) - %w(google_contacts_api siebel_donations))
  )

  # Exclude tests that are deprecated
  config.filter_run_excluding :deprecated

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include FactoryBot::Syntax::Methods
  config.include HeaderHelpers, type: :controller
  config.include JsonApiHelper, type: :acceptance
  config.include JsonApiHelper, type: :controller
  config.include JsonApiHelper, type: :request
  config.include MpdxHelpers
  config.include AuthHelper, :auth
  config.include ActiveSupport::Testing::TimeHelpers

  # Ensure jobs don't linger between tests
  config.before(:each) do
    Sidekiq::Worker.clear_all
  end
end

def response_json
  JSON.parse(response.body)
end

# locks the current time down to the second so we don't hit differences in updated_in_db_at
def lock_time_around
  around(:example) do |example|
    travel_to Time.zone.now, &example
  end
end
