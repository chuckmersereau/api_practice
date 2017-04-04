require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks' do
  include_context :json_headers
  documentation_scope = :entities_tasks

  let(:resource_type) { 'tasks' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:task) { create(:task, account_list: user.account_lists.first) }
  let(:id)    { task.uuid }

  let(:new_task) do
    attributes_for(:task)
      .reject { |key| key.to_s.end_with?('_id') }
      .except(:id, :completed, :notification_sent)
      .merge(updated_in_db_at: task.updated_at)
  end

  let(:form_data) do
    build_data(new_task, account_list_id: user.account_lists.first.uuid)
  end

  let(:resource_attributes) do
    %w(
      activity_type
      comments_count
      completed
      completed_at
      created_at
      next_action
      notification_time_before
      notification_time_unit
      notification_type
      result
      starred
      start_at
      subject
      tag_list
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      account_list
      comments
      contacts
      email_addresses
      people
      phone_numbers
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/tasks' do
      parameter 'filter[account_list_id]', 'Filter by Account List; Accepts Account List ID', required: false
      parameter 'filter[activity_type][]', 'Filter by Action; Accepts multiple parameters, with values "Call", "Appointment", "Email", '\
                                            '"Text Message", "Facebook Message", "Letter", "Newsletter", "Pre Call Letter", "Reminder Letter", '\
                                            '"Support Letter", "Thank", "To Do", "Talk to In Person", or "Prayer Request"',                     required: false
      parameter 'filter[completed]',       'Filter by Completed; Accepts values "true", or "false"',                                           required: false
      parameter 'filter[contact_ids][]',   'Filter by Contact IDs; Accepts multiple parameters, with Contact IDs',                             required: false
      parameter 'filter[date_range]',      'Filter by Date Range; Accepts values "last_month", "last_year", "last_two_years", "last_week", '\
                                            '"overdue", "today", "tomorrow", "future", and "upcoming"',                                         required: false
      parameter 'filter[no_date]',         'Filter by No Date; Accepts values "true", or "false"',                                             required: false
      parameter 'filter[overdue]',         'Filter by Overdue; Accepts values "true", or "false"',                                             required: false
      parameter 'filter[starred]',         'Filter by Starred; Accepts values "true", or "false"',                                             required: false
      parameter 'filter[tags][]',          'Filter by Tags; Accepts multiple parameters, with text values',                                    required: false

      with_options scope: :sort do
        parameter :completed_at, 'Sort by CompletedAt'
        parameter :created_at,   'Sort By CreatedAt'
        parameter :updated_at,   'Sort By UpdatedAt'
      end

      response_field :data, 'list of task objects', 'Type' => 'Array[Object]'
      response_field :data, 'list of task objects', type: 'Array[Object]'

      example 'List tasks', document: documentation_scope do
        do_request
        explanation 'List of Tasks associated to current_user'
        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Task'

      with_options scope: :data do
        response_field 'id',            'Task id',                                           type: 'Number'
        response_field 'relationships', 'List of relationships related to that task object', type: 'Array[Object]'
        response_field 'type',          'Type of object (Task in this case)',                type: 'String'

        with_options scope: :attributes do
          response_field 'account_list_id',          'Account List Id',          'Type' => 'Number'
          response_field 'activity_type',            'Activity Type',            'Type' => 'String'
          response_field 'created_at',               'Created At',               'Type' => 'String'
          response_field 'comments_count',           'Comments Count',           'Type' => 'Number'
          response_field 'completed',                'Completed',                'Type' => 'Boolean'
          response_field 'completed_at',             'Completed At',             'Type' => 'String'
          response_field 'due_date',                 'Due Date',                 'Type' => 'String'
          response_field 'next_action',              'Next Action',              'Type' => 'String'
          response_field 'notification_time_before', 'Notification Time Before', 'Type' => 'Number'
          response_field 'notification_time_unit',   'Notification Time Unit',   'Type' => 'String'
          response_field 'notification_type',        'Notification Type',        'Type' => 'String'
          response_field 'restult',                  'Result',                   'Type' => 'String'
          response_field 'starred',                  'Starred',                  'Type' => 'Boolean'
          response_field 'start_at',                 'Start At',                 'Type' => 'String'
          response_field 'subject',                  'Subject',                  'Type' => 'String'
          response_field 'tag_list',                 'Tag List',                 'Type' => 'String'
          response_field 'updated_at',               'Updated At',               'Type' => 'String'
          response_field 'updated_in_db_at',         'Updated In Db At',         'Type' => 'String'
        end
      end

      example 'Retrieve a task', document: documentation_scope do
        explanation 'The current_user\'s Task with the given ID'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/tasks' do
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id',          'Account List Id',          type: 'Number'
        parameter 'activity_type',            'Activity Type',            type: 'String'
        parameter 'completed',                'Completed',                type: 'Boolean'
        parameter 'end_at',                   'End At',                   type: 'String'
        parameter 'location',                 'Location',                 type: 'String'
        parameter 'next_action',              'Next Action',              type: 'String'
        parameter 'notification_time_before', 'Notification Time Before', type: 'Number'
        parameter 'notification_time_unit',   'Notification Time Unit',   type: 'String'
        parameter 'notification_type',        'Notification Type',        type: 'String'
        parameter 'remote_id',                'Remote Id',                type: 'String'
        parameter 'result',                   'Result',                   type: 'String'
        parameter 'source',                   'Source',                   type: 'String'
        parameter 'starred',                  'Starred',                  type: 'Boolean'
        parameter 'start_at',                 'Start At',                 type: 'String'
        parameter 'subject',                  'Subject',                  type: 'String', required: true
        parameter 'type',                     'Type',                     type: 'String'
      end

      example 'Create a task', document: documentation_scope do
        explanation 'Create a Task associated with the current_user'

        do_request data: form_data

        expect(resource_object['subject']).to eq new_task[:subject]
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/tasks/:id' do
      parameter :id, 'the Id of the Task'

      with_options scope: [:data, :attributes] do
        parameter 'account_list_id',          'Account List Id',          type: 'Number'
        parameter 'activity_type',            'Activity Type',            type: 'String'
        parameter 'completed',                'Completed',                type: 'Boolean'
        parameter 'end_at',                   'End At',                   type: 'String'
        parameter 'location',                 'Location',                 type: 'String'
        parameter 'next_action',              'Next Action',              type: 'String'
        parameter 'no_date',                  'No Date',                  type: 'Boolean'
        parameter 'notification_time_before', 'Notification Time Before', type: 'Number'
        parameter 'notification_time_unit',   'Notification Time Unit',   type: 'String'
        parameter 'notification_type',        'Notification Type',        type: 'String'
        parameter 'remote_id',                'Remote Id',                type: 'String'
        parameter 'result',                   'Result',                   type: 'String'
        parameter 'source',                   'Source',                   type: 'String'
        parameter 'starred',                  'Starred',                  type: 'Boolean'
        parameter 'start_at',                 'Start At',                 type: 'String'
        parameter 'subject',                  'Subject',                  type: 'String', required: true
        parameter 'type',                     'Type',                     type: 'String'
      end

      example 'Update a task', document: documentation_scope do
        explanation 'Update the current_user\'s Task with the given ID'

        do_request data: form_data
        expect(resource_object['subject']).to eq new_task[:subject]
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/tasks/:id' do
      parameter 'id', 'the Id of the Task'

      example 'Delete a task', document: documentation_scope do
        explanation 'Delete the current_user\'s Task with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
