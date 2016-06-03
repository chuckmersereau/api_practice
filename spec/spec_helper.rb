if ENV['COVERALLS_REPO_TOKEN']
  require 'coveralls'
  Coveralls.wear_merged!('rails')
end

def start_simplecov
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter 'vendor'
    add_filter '/dev/'
    add_group 'Roles', 'app/roles'
  end
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'webmock/rspec'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'sidekiq/testing'
require 'sidekiq_unique_jobs/testing'
require 'paper_trail/frameworks/rspec'
require 'attributes_history/rspec'

require 'rspec/matchers' # req by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'

# Turn off sidekiq logging in test
Sidekiq::Logging.logger = nil

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Base.establish_connection(:test)

WebMock.disable_net_connect!(allow_localhost: true)
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false, timeout: 60)
end
Capybara.javascript_driver = :poltergeist

Capybara.default_max_wait_time = 4

RSpec.configure do |config|
  config.before(:each) do |example|
    # Clears out the jobs for tests using the fake testing
    Sidekiq::Worker.clear_all

    case
    when example.metadata[:sidekiq] == :fake
      Sidekiq::Testing.fake!
    when example.metadata[:sidekiq] == :testing_disabled
      Sidekiq::Testing.disable!
    when example.metadata[:sidekiq] == :acceptance
      Sidekiq::Testing.inline!
    when example.metadata[:type] == :acceptance
      Sidekiq::Testing.inline!
    else
      Sidekiq::Testing.fake!
    end

    # Travis had an issue where the locale sometimes switched to French
    I18n.locale = :en_US

    # Stub the Google geocoder by default (creating an address calls it so it's
    # needed a lot)
    stub_google_geocoder
  end

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  config.include ActiveSupport::Testing::TimeHelpers

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.filter_run focus: true
  config.filter_run_excluding js: true
  config.run_all_when_everything_filtered = true
  config.include Devise::TestHelpers, type: :controller
  config.include FactoryGirl::Syntax::Methods

  # This adds automatic meta-data for specs by location (e.g. for controllers)
  config.infer_spec_type_from_file_location!

  # Exclude gems from spec backtraces, except a few directly related to our app
  config.filter_gems_from_backtrace(*(Gem::Specification.map(&:name) -
                                      %w(google_contacts_api siebel_donations)))

  config.order = :random
  config.silence_filter_announcements = true

  # Reset seed each time this file is loaded, so that spring won't cache seed
  # To run a spec with a specific seed, use --order=rand:[seed]
  config.seed = srand % 0xFFFF unless ARGV.any? { |arg| arg =~ /seed/ }

  if Rails.env.test?
    config.before(:suite) do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
      Rails.application.load_seed
    end

    config.before(:each, js: true) do
      DatabaseCleaner.strategy = :truncation
    end

    config.before(:each) do
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end

  REDIS_PID = "#{Rails.root}/tmp/pids/redis-test.pid".freeze
  REDIS_CACHE_PATH = "#{Rails.root}/tmp/cache/".freeze

  # config.before(:suite) do
  # redis_options = {
  # "daemonize"     => 'yes',
  # "pidfile"       => REDIS_PID,
  # "port"          => 9736,
  # "timeout"       => 300,
  # "save 900"      => 1,
  # "save 300"      => 1,
  # "save 60"       => 10000,
  # "dbfilename"    => "dump.rdb",
  # "dir"           => REDIS_CACHE_PATH,
  # "loglevel"      => "debug",
  # "logfile"       => "stdout",
  # "databases"     => 16
  # }.map { |k, v| "#{k} #{v}" }.join('\n')
  # `echo '#{redis_options}' | redis-server -`
  # end

  # config.after(:suite) do
  # %x{
  # cat #{REDIS_PID} | xargs kill -QUIT
  # rm -f #{REDIS_CACHE_PATH}dump.rdb
  # }
  # end
end

# This code will be run each time you run your specs.
start_simplecov unless ENV['NO_COVERAGE'].present?
Zonebie.quiet = true
Zonebie.set_random_timezone
FactoryGirl.reload
Dir[Rails.root.join('app/roles/**/*.rb')].each { |f| require f }

# Suppress debug-level "Geocoder: HTTP request being made ..." in spec output
Geocoder.configure(lookup: :test)
Geocoder::Lookup::Test.set_default_stub(
  [
    {
      'latitude'     => 40.7,
      'longitude'    => -74.0,
      'address'      => 'New York, NY, USA',
      'state'        => 'New York',
      'state_code'   => 'NY',
      'country'      => 'United States',
      'country_code' => 'US'
    }
  ]
)

def login(user)
  $request_test = true
  $user = user
end

def logout_test_user
  $request_test = false
  $user = nil
  sign_out(:user)
end

def stub_google_geocoder
  stub_request(:get, %r{maps\.googleapis\.com/maps/api.*}).to_return(body: '{}')
end

def stub_smarty_streets
  stub_request(:get, %r{https://api\.smartystreets\.com/street-address/.*})
    .to_return(body: '[]')
end

class FakeApi
  def initialize(*_args)
  end

  def self.requires_username_and_password?
    true
  end

  def requires_username_and_password?
    self.class.requires_username_and_password?
  end

  def validate_username_and_password(*_args)
    true
  end

  def profiles
    []
  end

  def profiles_with_designation_numbers
    []
  end

  def method_missing(*_args, &_block)
    true
  end
end

# Clear out unique job locks. They can get into Redis if you interrupt a test
# run or don't call Worker.clear after queuing jobs in a spec.
def clear_uniqueness_locks
  Sidekiq.redis do |redis|
    redis.keys('*unique*').each { |k| redis.del(k) }
  end
end

# locally, the orgs are seeded if you run rake db:test:prepare, but in
# Travis the database is fully empty since it just loads structure.sql
def org_for_code(code)
  Organization.find_by(code: code) ||
    create(:organization, name: code, code: code)
end
