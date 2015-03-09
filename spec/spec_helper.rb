# uncomment the following line to use spork with the debugger
# require 'spork/ext/ruby-debug'

def start_simplecov
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter 'vendor'
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

require 'rspec/matchers' # req by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

WebMock.disable_net_connect!(allow_localhost: true)
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false, timeout: 60)
end
Capybara.javascript_driver = :poltergeist

RSpec.configure do |config|
  config.before(:each) do |example_method|
    # Clears out the jobs for tests using the fake testing
    Sidekiq::Worker.clear_all
    # Get the current example from the example_method object
    example = example_method.example

    if example.metadata[:sidekiq] == :fake
      Sidekiq::Testing.fake!
    elsif example.metadata[:sidekiq] == :inline
      Sidekiq::Testing.inline!
    elsif example.metadata[:type] == :acceptance
      Sidekiq::Testing.inline!
    else
      Sidekiq::Testing.fake!
    end
  end
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

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
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run focus: true
  config.filter_run_excluding js: true
  config.run_all_when_everything_filtered = true
  config.include Devise::TestHelpers, type: :controller
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
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

  REDIS_PID = "#{Rails.root}/tmp/pids/redis-test.pid"
  REDIS_CACHE_PATH = "#{Rails.root}/tmp/cache/"

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
start_simplecov if ENV['DRB']
Zonebie.set_random_timezone
FactoryGirl.reload
Dir[Rails.root.join('app/roles/**/*.rb')].each { |f| require f }

def login(user)
  $request_test = true
  $user = user
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
