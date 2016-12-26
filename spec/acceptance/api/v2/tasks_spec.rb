require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks' do
  include_context :json_headers

  let(:resource_type) { 'tasks' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:task) { create(:task, account_list: user.account_lists.first) }
  let(:id)    { task.uuid }

  let(:new_task) do
    build(:task).attributes.merge(account_list_id: user.account_lists.first.uuid,
                                  updated_in_db_at: task.updated_at)
  end
  let(:form_data) { build_data(new_task) }

  let(:resource_attributes) do
    %w(
      account_list_id
      activity_type
      comments_count
      completed
      completed_at
      created_at
      due_date
      next_action
      no_date
      result
      starred
      start_at
      subject
      tag_list
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/tasks' do
      response_field :data, 'list of task objects', 'Type' => 'Array[Object]'

      example 'Task [LIST]', document: :entities do
        do_request
        explanation 'List of Tasks associated to current_user'

        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Task'

      with_options scope: :data do
        response_field 'id',            'Task id',                                           'Type' => 'Number'
        response_field 'relationships', 'List of relationships related to that task object', 'Type' => 'Array[Object]'
        response_field 'type',          'Type of object (Task in this case)',                'Type' => 'String'

        with_options scope: :attributes do
          response_field 'account_list_id',  'Account List Id',  type: 'Number'
          response_field 'activity_type',    'Activity Type',    type: 'String'
          response_field 'created_at',       'Created At',       type: 'String'
          response_field 'comments_count',   'Comments Count',   type: 'Number'
          response_field 'completed',        'Completed',        type: 'Boolean'
          response_field 'completed_at',     'Completed At',     type: 'String'
          response_field 'due_date',         'Due Date',         type: 'String'
          response_field 'next_action',      'Next Action',      type: 'String'
          response_field 'no_date',          'No Date',          type: 'Boolean'
          response_field 'restult',          'Result',           type: 'String'
          response_field 'starred',          'Starred',          type: 'Boolean'
          response_field 'start_at',         'Start At',         type: 'String'
          response_field 'subject',          'Subject',          type: 'String'
          response_field 'tag_list',         'Tag List',         type: 'String'
          response_field 'updated_at',       'Updated At',       type: 'String'
          response_field 'updated_in_db_at', 'Updated In Db At', type: 'String'
        end
      end

      example 'Task [GET]', document: :entities do
        explanation 'The current_user\'s Task with the given ID'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/tasks' do
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id', 'Account List Id', type: 'Number'
        parameter 'activity_type',   'Activity Type',   type: 'String'
        parameter 'starred',         'Starred',         type: 'Boolean'
        parameter 'start_at',        'Start At',        type: 'String'
        parameter 'subject',         'Subject',         type: 'Number', required: true
      end

      example 'Task [CREATE]', document: :entities do
        explanation 'Create a Task associated with the current_user'
        do_request data: form_data
        expect(resource_object['subject']).to eq new_task['subject']
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Task'

      with_options scope: [:data, :attributes] do
        parameter 'account_list_id', 'Account List Id', type: 'Number'
        parameter 'activity_type',   'Activity Type',   type: 'String'
        parameter 'starred',         'Starred',         type: 'Boolean'
        parameter 'start_at',        'Start At',        type: 'String'
        parameter 'subject',         'Subject',         type: 'Number', required: true
      end

      example 'Task [UPDATE]', document: :entities do
        explanation 'Update the current_user\'s Task with the given ID'
        do_request data: form_data
        expect(resource_object['subject']).to eq new_task['subject']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/tasks/:id' do
      parameter 'id', 'the Id of the Task'

      example 'Task [DELETE]', document: :entities do
        explanation 'Delete the current_user\'s Task with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
