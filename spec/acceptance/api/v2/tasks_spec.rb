require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Google Accounts' do
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
      response_field :data, 'list of google account objects', 'Type' => 'Array'

      example_request 'get organization accounts' do
        explanation 'List of Organization Accounts associated to current_user'
        check_collection_resource(1, ['relationships'])
        expect(status).to eq 200
      end
    end

    get '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Google Account'

      with_options scope: :data do
        response_field :id, 'google account id', 'Type' => 'Integer'
        response_field :type, 'type of object (GoogleAccount in this case)', 'Type' => 'String'
        response_field :relationships, 'list of relationships related to that google account object', 'Type' => 'Array'
        with_options scope: :attributes do
          response_field :subject, 'Subject', type: 'Integer'
          response_field :account_list_id, 'Account List Id', type: 'Integer'
          response_field :starred, 'Starred', type: 'Boolean'
          response_field :start_at, 'Start At', type: 'Datetime'
          response_field :activity_type, 'Activity Type', type: 'String'
        end
      end
      example_request 'get organization account' do
        check_resource(['relationships'])
        expect(status).to eq 200
      end
    end

    post '/api/v2/tasks' do
      with_options scope: [:data, :attributes] do
        parameter :subject, 'Subject', type: 'Integer', required: true
        parameter :account_list_id, 'Account List Id', type: 'Integer'
        parameter :starred, 'Starred', type: 'Boolean'
        parameter :start_at, 'Start At', type: 'Datetime'
        parameter :activity_type, 'Activity Type', type: 'String'
      end

      example 'create task' do
        do_request data: form_data
        expect(resource_object['subject']).to eq new_task['subject']
        expect(status).to eq 200
      end
    end

    put '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Google Account'

      with_options scope: [:data, :attributes] do
        parameter :subject, 'Subject', type: 'Integer', required: true
        parameter :account_list_id, 'Account List Id', type: 'Integer'
        parameter :starred, 'Starred', type: 'Boolean'
        parameter :start_at, 'Start At', type: 'Datetime'
        parameter :activity_type, 'Activity Type', type: 'String'
      end

      example 'update task' do
        do_request data: form_data
        expect(resource_object['subject']).to eq new_task['subject']
        expect(status).to eq 200
      end
    end

    delete '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Google Account'

      example_request 'delete task' do
        expect(status).to eq 200
      end
    end
  end
end