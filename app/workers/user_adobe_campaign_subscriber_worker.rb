class UserAdobeCampaignSubscriberWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_user_adobe_campaign_subscriber

  sidekiq_retries_exhausted do |message, error|
    ::Rollbar.error(error.class.new(error.message), message)
  end

  def perform(user_id)
    User.subscribe_to_adobe_campaign(user_id)
  rescue ::JSON::ParserError, ::RestClient::ServiceUnavailable, ::RestClient::BadGateway, ::RestClient::GatewayTimeout => error
    ::Rollbar.silenced { raise error }
  end
end
