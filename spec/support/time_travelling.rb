RSpec.configure do |config|
  config.after(:each) do |_example|
    travel_back
    Timecop.return if defined?(Timecop) # Just in case someone tries to add Timecop again in the future :)
  end
end
