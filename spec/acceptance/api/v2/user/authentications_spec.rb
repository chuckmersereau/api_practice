require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'json'

resource 'User / Authentication' do
  include_context :json_headers

  let(:user)         { create(:user_with_account) }
  let(:access_token) { 'right_token' }

  parameter :access_token, 'valid access token from The Key or Relay'

  before do
    allow(User).to receive(:from_access_token).with('right_token').and_return(user)
    allow(User).to receive(:from_access_token).with('wrong_token').and_return(nil)
  end

  post '/api/v2/user/authentication' do
    parameter 'access_token',        'Access Token',   type: 'String'
    response_field 'json_web_token', 'Json Web Token', type: 'String'

    example 'Authentication [CREATE]', document: false do
      explanation 'Authenticate current_user with the provided Access Token'
      do_request
      expect(response_status).to eq(201)
      expect(JsonWebToken.decode(JSON.parse(response_body)['json_web_token'])).to eq('user_uuid' => user.uuid)
    end
  end
end
