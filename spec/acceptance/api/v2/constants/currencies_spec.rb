require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Currencies' do
  include_context :json_headers

  let(:resource_type) { 'currencies' }
  let(:user) { create(:user_with_account) }

  let(:expected_attribute_keys) do
    %w(
      currencies
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/constants/currencies' do
      example 'Currency [LIST]', document: :constants do
        explanation 'List of Currency Constants'
        do_request

        expect(response_status).to eq 200
        expect(resource_object.keys).to match_array expected_attribute_keys

        resource_object['currencies'].each do |currency|
          expect(currency.size).to eq 2
          expect(currency.first).to be_a(String)
          expect(currency.second).to be_a(String)
        end
      end
    end
  end
end
