require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks Bulk' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: :tasks)

  let!(:account_list)  { user.account_lists.order(:created_at).first }
  let!(:task_one)      { create(:task, account_list: account_list) }
  let!(:task_two)      { create(:task, account_list: account_list) }
  let!(:resource_type) { 'tasks' }
  let!(:user)          { create(:user_with_account) }

  let(:new_task) do
    attributes_for(:task)
      .reject { |key| key.to_s.end_with?('_id') }
      .except(:id, :completed, :notification_sent)
      .merge(updated_in_db_at: task_one.updated_at)
  end

  let(:account_list_relationship) do
    {
      account_list: {
        data: {
          id: account_list.id,
          type: 'account_lists'
        }
      }
    }
  end

  let(:bulk_create_form_data) do
    [{ data: { type: resource_type, id: SecureRandom.uuid, attributes: new_task, relationships: account_list_relationship } }]
  end

  let(:bulk_update_form_data) do
    [{ data: { type: resource_type, id: task_one.id, attributes: new_task } }]
  end

  context 'authorized user' do
    post '/api/v2/tasks/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_create, context: self)

      example doc_helper.title_for(:bulk_create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_create)
        do_request data: bulk_create_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['subject']).to eq new_task[:subject]
      end
    end

    put '/api/v2/tasks/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_update, context: self)

      example doc_helper.title_for(:bulk_update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_update)
        do_request data: bulk_update_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['subject']).to eq new_task[:subject]
      end
    end

    before { api_login(user) }

    delete '/api/v2/tasks/bulk' do
      with_options scope: :data do
        parameter :id, 'Each member of the array must contain the id of the task being deleted'
      end
      doc_helper.insert_documentation_for(action: :bulk_delete, context: self)

      example doc_helper.title_for(:bulk_delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_delete)
        do_request data: [
          { data: { type: resource_type, id: task_one.id } },
          { data: { type: resource_type, id: task_two.id } }
        ]

        expect(response_status).to eq(200)
        expect(json_response.size).to eq(2)
        expect(json_response.collect { |hash| hash.dig('data', 'id') }).to match_array([task_one.id, task_two.id])
      end
    end
  end
end
