require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks > Analytics' do
  include_context :json_headers
  documentation_scope = :tasks_api_analytics

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'task_analytics' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:alternate_account_list) do
    create(:account_list).tap do |account_list|
      user.account_lists << account_list
    end
  end

  let!(:overdue_tasks) do
    Task::TASK_ACTIVITIES.each do |activity_type|
      trait_key = activity_type.parameterize.underscore.to_sym

      create(:task, trait_key, :overdue, account_list: account_list)
    end
  end

  let!(:last_physical_newsletter_logged_for_primary_account_list) do
    create(:task,
           :newsletter_physical,
           :complete,
           account_list: account_list,
           completed_at: 1.day.ago)
  end

  let!(:last_electronic_newsletter_logged_for_primary_account_list) do
    create(:task,
           :newsletter_email,
           :complete,
           account_list: account_list,
           completed_at: 1.day.ago)
  end

  let!(:last_electronic_newsletter_logged_for_alterate_account_list) do
    create(:task,
           :newsletter_email,
           :complete,
           account_list: alternate_account_list,
           completed_at: 2.days.ago)
  end

  # List your expected resource keys vertically here (alphabetical please!)
  let(:expected_attribute_keys) do
    %w(
      created_at
      last_electronic_newsletter_completed_at
      last_physical_newsletter_completed_at
      tasks_overdue_or_due_today_counts
      total_tasks_due_count
      updated_at
      updated_in_db_at
    )
  end

  let(:returned_electronic_newsletter_completed_at) do
    json_response['data']['attributes']['last_electronic_newsletter_completed_at']
  end

  let(:returned_physical_newsletter_completed_at) do
    json_response['data']['attributes']['last_physical_newsletter_completed_at']
  end

  let(:returned_overdue_or_due_today_data) do
    json_response['data']['attributes']['tasks_overdue_or_due_today_counts']
  end

  let(:returned_total_tasks_due_count) do
    json_response['data']['attributes']['total_tasks_due_count']
  end

  context 'authorized user' do
    before { api_login(user) }

    context 'without specifying an `account_list_id`' do
      # show
      get '/api/v2/tasks/analytics' do
        with_options scope: [:data, :attributes] do
          response_field 'last_electronic_newsletter_completed_at', 'Last Electronic Newsletter Completed At', type: 'DateTime'
          response_field 'last_physical_newsletter_completed_at',   'Last Physical Newsletter Completed At',   type: 'DateTime'
          response_field 'tasks_overdue_or_due_today_counts',       'Tasks Overdue or Due Today Counts',       type: 'Array[Object]'
          response_field 'total_tasks_due_count',                   'Total Tasks Due Count',                   type: 'Number'
        end

        example 'Analytics [GET]', document: documentation_scope do
          explanation "Viewing Analytical information for the User's Tasks for all Account Lists"
          do_request

          check_resource
          expect(resource_object.keys).to match_array expected_attribute_keys
          expect(response_status).to eq 200

          expect(returned_electronic_newsletter_completed_at)
            .to eq(
              last_electronic_newsletter_logged_for_primary_account_list
                .completed_at
                .to_time
                .utc
                .iso8601
            )

          expect(returned_physical_newsletter_completed_at)
            .to eq(
              last_physical_newsletter_logged_for_primary_account_list
                .completed_at
                .to_time
                .utc
                .iso8601
            )

          expect(returned_overdue_or_due_today_data.count)
            .to eq Task::TASK_ACTIVITIES.count

          expect(returned_total_tasks_due_count)
            .to eq Task::TASK_ACTIVITIES.count
        end
      end
    end

    context 'when specifying an `account_list_id`' do
      # show
      get '/api/v2/tasks/analytics' do
        with_options scope: [:data, :attributes] do
          response_field 'last_electronic_newsletter_completed_at', 'Last Electronic Newsletter Completed At', type: 'DateTime'
          response_field 'last_physical_newsletter_completed_at',   'Last Physical Newsletter Completed At',   type: 'DateTime'
          response_field 'tasks_overdue_or_due_today_counts',       'Tasks Overdue or Due Today Counts',       type: 'Array[Object]'
          response_field 'total_tasks_due_count',                   'Total Tasks Due Count',                   type: 'Number'
        end

        example 'Analytics [GET]', document: documentation_scope do
          explanation "Viewing Analytical information for a specific Account Lists' Tasks"
          do_request filter: { account_list_id: alternate_account_list.uuid }

          check_resource
          expect(resource_object.keys).to match_array expected_attribute_keys
          expect(response_status).to eq 200

          expect(returned_electronic_newsletter_completed_at)
            .to eq(
              last_electronic_newsletter_logged_for_alterate_account_list
                .completed_at
                .to_time
                .utc
                .iso8601
            )

          expect(returned_physical_newsletter_completed_at)
            .to be_nil

          expect(returned_overdue_or_due_today_data.count)
            .to eq Task::TASK_ACTIVITIES.count

          expect(returned_total_tasks_due_count)
            .to eq 0
        end
      end
    end
  end
end
