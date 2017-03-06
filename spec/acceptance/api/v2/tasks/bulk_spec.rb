require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks Bulk' do
  include_context :json_headers
  documentation_scope = :entities_tasks

  let!(:account_list)  { user.account_lists.first }
  let!(:task_one)      { create(:task, account_list: account_list) }
  let!(:task_two)      { create(:task, account_list: account_list) }
  let!(:resource_type) { 'tasks' }
  let!(:user)          { create(:user_with_account) }

  let(:new_task) do
    build(:task)
      .attributes
      .reject { |key| key.to_s.end_with?('_id') }
      .except('id', 'completed', 'notification_sent')
      .merge(updated_in_db_at: task_one.updated_at)
  end

  let(:account_list_relationship) do
    {
      account_list: {
        data: {
          id: account_list.uuid,
          type: 'account_lists'
        }
      }
    }
  end

  let(:bulk_create_form_data) do
    [{ data: { type: resource_type, id: SecureRandom.uuid, attributes: new_task, relationships: account_list_relationship } }]
  end

  let(:bulk_update_form_data) do
    [{ data: { type: resource_type, id: task_one.uuid, attributes: new_task } }]
  end

  context 'authorized user' do
    post '/api/v2/tasks/bulk' do
      with_options scope: :data do
        parameter 'id',         'Each member of the array must contain the id of the task being created',                  'Type' =>  'String'
        parameter 'type',       "Each member of the array must contain the type 'tasks'",                                  'Type' =>  'String'
        parameter 'attributes', 'Each member of the array must contain an object with the attributes of the task created', 'Type' =>  'Object'
      end

      example 'Task [CREATE] [BULK]', document: documentation_scope do
        explanation 'Bulk Create a list of Tasks with an array of objects containing the ID and attributes'
        do_request data: bulk_create_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['subject']).to eq new_task['subject']
      end
    end

    put '/api/v2/tasks/bulk' do
      with_options scope: :data do
        parameter 'id',         'Each member of the array must contain the id of the task being updated',                   'Type' =>  'String'
        parameter 'type',       "Each member of the array must contain the type 'tasks'",                                   'Type' =>  'String'
        parameter 'attributes', 'Each member of the array must contain an object with the attributes that must be updated', 'Type' =>  'Object'
      end

      response_field 'data',
                     'List of Task objects that have been successfully updated and list of errors related to Task objects that were not updated successfully',
                     'Type' => 'Array[Object]'

      example 'Task [UPDATE] [BULK]', document: documentation_scope do
        explanation 'Bulk Update a list of Tasks with an array of objects containing the ID and updated attributes'
        do_request data: bulk_update_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['subject']).to eq new_task['subject']
      end
    end

    before { api_login(user) }

    delete '/api/v2/tasks/bulk' do
      with_options scope: :data do
        parameter :id, 'Each member of the array must contain the id of the task being deleted'
      end

      example 'Task [DELETE] [BULK]', document: documentation_scope do
        explanation 'Bulk delete Tasks with the given IDs'
        do_request data: [
          { data: { type: resource_type, id: task_one.uuid } },
          { data: { type: resource_type, id: task_two.uuid } }
        ]

        expect(response_status).to eq(200)
        expect(json_response.size).to eq(2)
        expect(json_response.collect { |hash| hash.dig('data', 'id') }).to match_array([task_one.uuid, task_two.uuid])
      end
    end
  end
end
