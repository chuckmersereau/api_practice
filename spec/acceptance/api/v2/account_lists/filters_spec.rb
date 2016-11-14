require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Filters' do
  let(:resource_type) { 'account-lists' }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account_lists/:account_list_id/filters' do
      let(:contact) { 1 }
      let(:task) { 1 }
      parameter :contact,                       'Contact', 'Type' => 'Boolean'
      parameter :task,                          'Task', 'Type' => 'Boolean'
      response_field 'contact-filters',         'Contact Filters', 'Type' => 'Hash'
      response_field 'task-filters',            'Task Filters', 'Type' => 'Hash'
      example_request 'get filters for contacts and tasks' do
        expect(json_response.keys).to eq %w(contact_filters task_filters)
        expect(status).to eq 200
      end
    end
  end
end
