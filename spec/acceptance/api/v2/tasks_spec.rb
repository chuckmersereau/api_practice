require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks' do
  let(:resource_type) { 'tasks' }
  let!(:user) { create(:user_with_full_account) }
  let!(:task) { create(:task, account_list: user.account_lists.first) }
  let(:id) { task.id }
  let(:new_task) { build(:task, account_list: user.account_lists.first).attributes }
  let(:form_data) { build_data(new_task) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/tasks' do
      response_field :data, 'list of task objects', 'Type' => 'Array'

      example_request 'get tasks' do
        explanation 'List of Tasks associated to current_user'
        check_collection_resource(1, ['relationships'])
        expect(status).to eq 200
      end
    end

    get '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Task'

      with_options scope: :data do
        response_field 'id',                  'task id', 'Type' => 'Integer'
        response_field 'relationships',       'list of relationships related to that task object', 'Type' => 'Array'
        response_field 'type',                'type of object (Task in this case)', 'Type' => 'String'
        with_options scope: :attributes do
          response_field 'account_list_id',   'Account List Id', type: 'Integer'
          response_field 'activity_type',     'Activity Type', type: 'String'
          response_field 'starred',           'Starred', type: 'Boolean'
          response_field 'start_at',          'Start At', type: 'Datetime'
          response_field 'subject',           'Subject', type: 'Integer'
        end
      end
      example_request 'get task' do
        check_resource(['relationships'])
        expect(status).to eq 200
      end
    end

    post '/api/v2/tasks' do
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id',          'Account List Id', type: 'Integer'
        parameter 'activity_type',            'Activity Type', type: 'String'
        parameter 'starred',                  'Starred', type: 'Boolean'
        parameter 'start_at',                 'Start At', type: 'Datetime'
        parameter 'subject',                  'Subject', type: 'Integer', required: true
      end

      example 'create task' do
        do_request data: form_data
        expect(resource_object['subject']).to eq new_task['subject']
        expect(status).to eq 200
      end
    end

    put '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Task'

      with_options scope: [:data, :attributes] do
        parameter 'account_list_id',          'Account List Id', type: 'Integer'
        parameter 'activity_type',            'Activity Type', type: 'String'
        parameter 'starred',                  'Starred', type: 'Boolean'
        parameter 'start_at',                 'Start At', type: 'Datetime'
        parameter 'subject',                  'Subject', type: 'Integer', required: true
      end

      example 'update task' do
        do_request data: form_data
        expect(resource_object['subject']).to eq new_task['subject']
        expect(status).to eq 200
      end
    end

    delete '/api/v2/tasks/:id' do
      parameter 'id', 'the Id of the Task'

      example_request 'delete task' do
        expect(status).to eq 200
      end
    end
  end
end
