require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'json'

resource 'User / Authenticate' do
  include_context :json_headers

  let!(:user) { create(:user) }

  before do
    user.relay_accounts << create(:relay_account, relay_remote_id: 'B163530-7372-551R-KO83-1FR05534129F')
    stub_request(:get, 'https://thekey.me/cas/p3/serviceValidate?service=http://example.org/api/v2/user/authenticate&ticket=ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a')
      .to_return(status: 200, body: File.open(Rails.root.join('spec', 'fixtures', 'cas', 'successful_ticket_validation_response_body.xml')).read)
  end

  post '/api/v2/user/authenticate' do
    with_options scope: [:data, :attributes] do
      parameter 'cas_ticket',          'A valid CAS Ticket from The Key or Relay', type: 'String'
      response_field 'json_web_token', 'JSON Web Token',                           type: 'String'
    end

    example 'Authenticate [CREATE]', document: :user do
      explanation 'Create a JSON Web Token from a provided valid CAS Ticket'
      do_request data: { type: 'authenticate', attributes: { cas_ticket: 'ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a' } }
      expect(response_status).to eq(200)
      expect(JsonWebToken.decode(JSON.parse(response_body)['data']['attributes']['json_web_token'])['user_id']).to eq(user.id)
    end
  end
end
