require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Filters' do
  let(:resource_type) { 'account-lists' }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let(:expected_attribute_keys) do
    %w(contact_filters
       task_filters)
  end

  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account-lists/:account_list_id/filters' do
      with_options scope: [:filters] do
        parameter 'contact',                      'Contact', 'Type' => 'Boolean'
        parameter 'task',                         'Task', 'Type' => 'Boolean'
      end
      response_field 'contact-filters',         'Contact Filters', 'Type' => 'Object'
      response_field 'task-filters',            'Task Filters', 'Type' => 'Object'
      example 'get filters for contacts and tasks' do
        do_request filters: { contact: 1, task: 1 }
        expect(json_response.keys).to match_array expected_attribute_keys
        expect(status).to eq 200
      end
    end
  end
end
