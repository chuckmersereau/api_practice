SiebelDonations.configure do |config|
  config.oauth_token = ENV['WSAPI_KEY']
  config.default_timeout = 60000
  config.base_url = 'https://wsapi.ccci.org/wsapi/rest'
end
