require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks > Comments' do
  include_context :json_headers
  documentation_scope = :tasks_api_comments

  let!(:user) { create(:user_with_full_account) }
  let(:resource_type) { :comments }

  let(:account_list) { user.account_lists.first }
  let(:person) { create(:contact_with_person, account_list: account_list).reload.people.first }
  let(:task)    { create(:task, account_list: user.account_lists.first) }
  let(:task_id) { task.uuid }

  let!(:comment) { create(:activity_comment, activity: task) }
  let(:id) { comment.uuid }

  let(:new_comment) do
    build(:activity_comment, activity: task).attributes.with_indifferent_access.merge(updated_in_db_at: comment.updated_at, task_id: task_id).except(:activity_id, :person_id)
  end

  let(:form_data) do
    build_data(new_comment.slice(*ActivityComment::PERMITTED_ATTRIBUTES), relationships: {
                 person: {
                   data: {
                     type: 'people',
                     id: person.uuid
                   }
                 }
               })
  end

  let(:expected_attribute_keys) do
    %w(
      body
      created_at
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/tasks/:task_id/comments' do
      example 'Comment [LIST]', document: documentation_scope do
        explanation 'List of Comments associated to the Task'
        do_request

        check_collection_resource 1, ['relationships']
        expect(response_status).to eq(200)
      end
    end

    get '/api/v2/tasks/:task_id/comments/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'body',             'Comment body',     'Type' => 'String'
        response_field 'created_at',       'Created At',       'Type' => 'String'
        response_field 'updated_at',       'Updated At',       'Type' => 'String'
        response_field 'updated_in_db_at', 'Updated In Db At', 'Type' => 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'person', 'The person who wrote the comment', 'Type' => 'Object'
      end

      example 'Comment [GET]', document: documentation_scope do
        explanation "The Task's Comment with the given ID"
        do_request
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq(200)
      end
    end

    post '/api/v2/tasks/:task_id/comments' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'body', 'Comment body', 'Type' => 'String'
      end

      with_options scope: [:data, :relationships] do
        parameter 'person', 'The person who wrote the comment', 'Type' => 'Object'
      end

      example 'Comment [CREATE]', document: documentation_scope do
        explanation 'Create a Comment associated with the Task'
        do_request data: form_data

        expect(resource_object['body']).to(be_present) && eq(new_comment['body'])
        expect(response_status).to eq(201)
      end
    end

    put '/api/v2/tasks/:task_id/comments/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'body', 'Comment body', 'Type' => 'String'
      end

      with_options scope: [:data, :relationships] do
        parameter 'person', 'The person who wrote the comment', 'Type' => 'Object'
      end

      example 'Comment [UPDATE]', document: documentation_scope do
        explanation "Update the Task's Comment with the given ID"
        do_request data: form_data

        expect(resource_object['body']).to(be_present) && eq(new_comment['body'])
        expect(response_status).to eq(200)
      end
    end

    delete '/api/v2/tasks/:task_id/comments/:id' do
      example 'Comment [DELETE]', document: documentation_scope do
        explanation "Delete the Task's Comment with the given ID"
        do_request
        expect(response_status).to eq(204)
      end
    end
  end
end
