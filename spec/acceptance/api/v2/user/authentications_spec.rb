require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'User / Authentication' do
  let(:user) { create(:user_with_account) }
  let(:access_token) { 'right_token' }
  parameter :access_token, 'valid access token from The Key or Relay'

  before do
    allow(User).to receive(:from_access_token).with('right_token').and_return(user)
    allow(User).to receive(:from_access_token).with('wrong_token').and_return(nil)
  end

  post '/api/v2/user/authentication' do
    example_request 'Get Authentication' do
      expect(status).to eq(200)
      expect(JsonWebToken.decode(response_body)).to eq('user_id' => user.id)
    end
    example_request 'Get Authentication [Unathorized]', access_token: 'wrong_token' do
      expect(status).to eq(401)
      expect(json_response).to eq('errors' => ['Unauthorized'])
    end
  end
end
