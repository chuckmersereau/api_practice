RSpec.configure do |config|
  config.before(:each) do |_example|
    stub_google_geocoder
  end
end
