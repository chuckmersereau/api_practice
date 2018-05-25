require 'rails_helper'

describe UserAdobeCampaignSubscriberWorker do
  let!(:user) { create(:person_with_gender) }
  let(:email_address) { user.email_addresses.first.email }
  let(:attrs) do
    { email: email_address,
      firstName: user.first_name,
      lastName: user.last_name }
  end

  let(:user_agent) do
    "rest-client/2.0.2 (#{::RbConfig::CONFIG['host_os']} x86_64) ruby/2.5.1p57"
  end

  def content_length(hash)
    ::ActiveSupport::JSON.encode(hash).size
  end

  def auth_body
    { client_id: 'asdf',
      client_secret: 'asdf',
      jwt_token: 'asdf' }
  end

  def stub_all_requests
    adobe_login_stub
    adobe_campaign_stub
    adobe_campaign_profile_stub
    cru_campaign_stub
    cru_campaign_stub_post
    profile_services_stub
  end

  def adobe_login_stub
    headers = {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip, deflate',
      'Content-Length' => '48',
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Host' => 'ims-na1.adobelogin.com',
      'User-Agent' => user_agent
    }
    stub_request(:post, 'https://ims-na1.adobelogin.com/ims/exchange/jwt')
      .with(body: auth_body, headers: headers)
      .to_return(status: 200, body: { content: [] }.to_json, headers: {})
  end

  def adobe_campaign_stub
    headers = {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip, deflate',
      'Authorization' => 'Bearer',
      'Host' => 'mc.adobe.io',
      'User-Agent' => user_agent,
      'X-Api-Key' => 'asdf'
    }
    stub_request(:get, "https://mc.adobe.io/cru/campaign/profileAndServices/profile/byEmail?email=#{email_address}")
      .with(headers: headers)
      .to_return(status: 200, body: { content: [] }.to_json, headers: {})
  end

  def adobe_campaign_profile_stub
    headers = {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip, deflate',
      'Authorization' => 'Bearer',
      'Content-Length' => content_length(attrs),
      'Content-Type' => 'application/json',
      'Host' => 'mc.adobe.io',
      'User-Agent' => user_agent,
      'X-Api-Key' => 'asdf'
    }
    stub_request(:post, 'https://mc.adobe.io/cru/campaign/profileAndServices/profile')
      .with(body: attrs.to_json, headers: headers)
      .to_return(status: 200, body: { content: [{ serviceName: ENV['ADOBE_SERVICE_NAME'] }] }.to_json, headers: {})
  end

  def cru_campaign_stub
    headers = {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip, deflate',
      'Authorization' => 'Bearer',
      'Host' => 'mc.adobe.io',
      'User-Agent' => user_agent,
      'X-Api-Key' => 'asdf'
    }
    stub_request(:get, 'https://mc.adobe.io/cru/campaign/')
      .with(headers: headers)
      .to_return(status: 200, body: { subscriber: { PKey: '' } }.to_json, headers: {})
  end

  def cru_campaign_stub_post
    headers = {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip, deflate',
      'Authorization' => 'Bearer',
      'Content-Length' => '28',
      'Content-Type' => 'application/json',
      'Host' => 'mc.adobe.io',
      'User-Agent' => user_agent,
      'X-Api-Key' => 'asdf'
    }
    stub_request(:post, 'https://mc.adobe.io/cru/campaign/')
      .with(headers: headers)
      .to_return(status: 200, body: { content: [] }.to_json, headers: {})
  end

  def profile_services_stub
    headers = {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip, deflate',
      'Authorization' => 'Bearer',
      'Host' => 'mc.adobe.io',
      'User-Agent' => user_agent,
      'X-Api-Key' => 'asdf'
    }
    stub_request(:get, 'https://mc.adobe.io/cru/campaign/profileAndServices/service/byText?text=MPDXSVC44')
      .with(headers: headers)
      .to_return(status: 200, body: { content: [] }.to_json, headers: {})
  end

  it 'queues up adobe campaign subscription' do
    stub_all_requests
    expect do
      UserAdobeCampaignSubscriberWorker.perform_async(user.id)
    end.to change(UserAdobeCampaignSubscriberWorker.jobs, :size).by(1)
  end
end
