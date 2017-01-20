require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Activities' do
  include_context :json_headers

  let(:resource_type) { 'activities' }
  let(:user) { create(:user_with_account) }

  let(:expected_attribute_keys) do
    %w(
      activities
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/constants/activities' do
      example 'Activity [LIST]', document: :constants do
        explanation 'List of Activity Constants'
        do_request

        expect(response_status).to eq 200
        expect(resource_object.keys).to match_array expected_attribute_keys

        resource_object['activities'].each do |activity|
          expect(activity).to be_a(String)
        end
      end
    end
  end
end
