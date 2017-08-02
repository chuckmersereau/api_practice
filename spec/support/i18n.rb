RSpec.configure do |config|
  config.after(:each) do |_example|
    I18n.locale = I18n.default_locale
  end
end
