RSpec.configure do |config|
  config.after(:each) do |_example|
    CurrencyRate.clear_rate_cache
  end
end
