require 'rails_helper'

RSpec.describe ConvertCredentialsWorker do
  let(:oauth_convert_to_token_url) { 'https://example.com' }
  let(:username) { 'test@test.com' }
  let(:password) { 'test_password_1234' }
  let(:organization) { create(:fake_org, oauth_convert_to_token_url: oauth_convert_to_token_url) }
  let!(:organization_account) do
    create(
      :organization_account,
      organization: organization,
      username: username,
      password: password
    )
  end
  let(:response) do
    "IsValidLogin,Token,Scope\n\"True\",\"abc-123\",\"user-123 profile-*\"\n"
  end

  before do
    stub_request(:post, oauth_convert_to_token_url).to_return(body: response)
    allow(ENV).to receive(:fetch).with('DONORHUB_CLIENT_ID') { 'client_id' }
    allow(ENV).to receive(:fetch).with('DONORHUB_CLIENT_SECRET') { 'client_secret' }
  end

  describe '#perform' do
    it 'should call RestClient::Request.execute' do
      expect(RestClient::Request).to(
        receive(:execute).with(
          method: :post,
          url: oauth_convert_to_token_url,
          payload: {
            'UserName' => username,
            'Password' => password,
            'Action' => 'OAuthConvertToToken',
            'client_id' => 'client_id',
            'client_secret' => 'client_secret',
            'client_instance' => 'app'
          }
        ).and_call_original
      )
      subject.perform
    end
  end

  it 'should update organization_account' do
    subject.perform
    organization_account.reload
    expect(organization_account.username).to eq nil
    expect(organization_account.password).to eq nil
    expect(organization_account.token).to eq 'abc-123'
  end
end
