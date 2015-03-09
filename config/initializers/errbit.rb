Airbrake.configure do |config|
  config.api_key = '919b0e21430abfaf5206ca4cfe5b3e3c'
  config.host = 'errors.uscm.org'
  config.port = 443
  config.secure = config.port == 443
  config.ignore_only = config.ignore + [
    'Google::APIClient::ServerError', 'Net::IMAP::BadResponseError',
    'LowerRetryWorker::RetryJobButNoAirbrakeError'
  ]
end

module Airbrake
  def self.raise_or_notify(e, opts = {})
    if ::Rails.env.development? || ::Rails.env.test?
      raise e
    else
      Airbrake.notify_or_ignore(e, opts)
    end
  end
end
