SiebelDonations.configure do |config|
  config.oauth_token = ENV.fetch('WSAPI_KEY')
  config.default_timeout = 600
  config.base_url = 'https://wsapi.cru.org/wsapi/rest'
end
