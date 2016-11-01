if ENV['COVERALLS_REPO_TOKEN']
  require 'coveralls'
  Coveralls.wear!('rails')
end

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'rspec/matchers'
require 'paper_trail/frameworks/rspec'
require 'attributes_history/rspec'
require 'equivalent-xml'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Reset seed each time this file is loaded, so that spring won't cache seed
  # To run a spec with a specific seed, use --order=rand:[seed]
  config.seed = srand % 0xFFFF unless ARGV.any? { |arg| arg =~ /seed/ }
  config.order = :random
  config.example_status_persistence_file_path = 'recent_specs.txt'

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

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
    *(Gem::Specification.map(&:name) - %w(google_contacts_api siebel_donations)))

  # Exclude tests that are deprecated
  config.filter_run_excluding :deprecated

  config.include Devise::TestHelpers, type: :controller
  config.include FactoryGirl::Syntax::Methods
  config.include JsonApiHelper, type: :acceptance
  config.include MpdxHelper
  config.include ActiveSupport::Testing::TimeHelpers
end
