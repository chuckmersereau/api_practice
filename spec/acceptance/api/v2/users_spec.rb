require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'User' do
  let(:user) { create(:user_with_account) }
  get '/api/v2/user' do
    include_context :authorization
    example 'Get User' do
      do_request
      expect(status).to eq(200)
    end
  end
  get '/api/v2/user' do
    example 'Get User [Unathorized]' do
      do_request
      expect(status).to eq(401)
      expect(json_response).to eq('errors' => ['Unauthorized'])
    end
  end
end
