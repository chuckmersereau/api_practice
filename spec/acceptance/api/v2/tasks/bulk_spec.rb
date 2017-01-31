require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks Bulk' do
  include_context :json_headers

  let!(:account_list)  { user.account_lists.first }
  let!(:task_one)      { create(:task, account_list: account_list) }
  let!(:task_two)      { create(:task, account_list: account_list) }
  let!(:resource_type) { 'tasks' }
  let!(:user)          { create(:user_with_account) }

  context 'authorized user' do
    before { api_login(user) }

    delete '/api/v2/tasks/bulk' do
      with_options scope: :data do
        parameter :id, 'Each member of the array must contain the id of the task being deleted'
      end

      example 'Task [DELETE] [BULK]', document: :entities do
        explanation 'Bulk delete Tasks with the given IDs'
        do_request data: [{ data: { id: task_one.uuid } }, { data: { id: task_two.uuid } }]
        expect(response_status).to eq(200)
        expect(json_response.size).to eq(2)
        expect(json_response.collect { |hash| hash.dig('data', 'id') }).to match_array([task_one.uuid, task_two.uuid])
      end
    end
  end
end
