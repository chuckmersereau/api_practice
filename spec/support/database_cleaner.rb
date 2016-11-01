RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    Rails.application.load_seed
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
    stub_request(:get, %r{maps\.googleapis\.com/maps/api.*}).to_return(body: '{}')
  end

  config.after(:each) do |example|
    DatabaseCleaner.clean
    Rails.application.load_seed if example.metadata[:js]
  end
end
