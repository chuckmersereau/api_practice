require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Locales' do
  include_context :json_headers

  let(:resource_type) { 'organizations' }
  let(:user) { create(:user_with_account) }

  let(:expected_attribute_keys) do
    %w(
      organizations
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/constants/organizations' do
      example 'Organization [LIST]', document: :constants do
        explanation 'List of Organization Constants'
        do_request

        expect(response_status).to eq 200
        expect(resource_object.keys).to match_array expected_attribute_keys

        resource_object['organizations'].each do |organization|
          expect(organization.size).to eq 2
          expect(organization.first).to be_a(String)
          expect(organization.second).to be_a(Fixnum)
        end
      end
    end
  end
end
