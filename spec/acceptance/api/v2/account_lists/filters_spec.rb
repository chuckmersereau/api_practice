require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Filters' do
  header 'Content-Type', 'application/vnd.api+json'

  let(:resource_type) { 'account_lists' }
  let!(:user)         { create(:user_with_account) }

  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let(:expected_attribute_keys) do
    %w(
      contact_filters
      task_filters
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/filters' do
      with_options scope: [:filters] do
        parameter 'contact', 'Contact', 'Type' => 'Boolean'
        parameter 'task',    'Task',    'Type' => 'Boolean'
      end

      response_field 'contact_filters', 'Contact Filters', 'Type' => 'Object'
      response_field 'task_filters',    'Task Filters',    'Type' => 'Object'

      example 'Filter [LIST]', document: :account_lists do
        do_request filters: { contact: 1, task: 1 }
        expect(json_response.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
  end
end
