# frozen_string_literal: true

module AdobeCampaignable
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_adobe_campaign_subscription, on: :create
  end

  module ClassMethods
    def subscribe_to_adobe_campaign(user_id)
      find_by(id: user_id)&.find_or_create_adobe_subscription
    end

    def adobe_campaign_service
      ::Adobe::Campaign::Service.find(ENV['ADOBE_SERVICE_NAME']).dig('content', 0)
    end
  end

  def find_or_create_adobe_profile
    @adobe_profile ||= find_on_adobe_campaign
    @adobe_profile ||= post_to_adobe_campaign
  end

  def find_on_adobe_campaign
    ::Adobe::Campaign::Profile.by_email(email_address)['content'][0]
  end

  def post_to_adobe_campaign
    ::Adobe::Campaign::Profile.post(
      "email": email_address,
      "firstName": first_name,
      "lastName": last_name
    )
  end

  def find_or_create_adobe_subscription
    find_adobe_subscription || subscribe_to_adobe_campaign
  end

  def find_adobe_subscription
    profile = find_or_create_adobe_profile
    prof_subs_url = profile.fetch('subscriptions', {}).fetch('href', '')
    subscriptions = ::Adobe::Campaign::Base.get_request(prof_subs_url).fetch('content', [{ serviceName: nil }])
    subscriptions.find { |subcription| subcription['serviceName'] == ENV['ADOBE_SERVICE_NAME'] }
  end

  def subscribe_to_adobe_campaign
    profile = find_or_create_adobe_profile
    service_subs_url = (self.class.adobe_campaign_service || {}).fetch('subscriptions', {}).fetch('href', '')
    ::Adobe::Campaign::Service.post_subscription(service_subs_url, profile['PKey'])
  end

  private

  def enqueue_adobe_campaign_subscription
    return unless email_address =~ /@/ && Rails.env.production?
    UserAdobeCampaignSubscriberWorker.perform_async(id)
  end
end
