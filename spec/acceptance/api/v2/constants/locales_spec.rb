require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Locales' do
  include_context :json_headers

  let(:resource_type) { 'locales' }
  let(:user) { create(:user_with_account) }

  let(:expected_attribute_keys) do
    %w(
      locales
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/constants/locales' do
      example 'Locale [LIST]', document: :constants do
        explanation 'List of Locale Constants'
        do_request

        expect(response_status).to eq 200
        expect(resource_object.keys).to match_array expected_attribute_keys

        resource_object['locales'].each do |currency|
          expect(currency.size).to eq 2
          expect(currency.first).to be_a(String)
          expect(currency.second).to be_a(String)
        end
      end
    end
  end
end
