require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks > Tags > Bulk Delete' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:tasks, :tags])

  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let(:tag_one)   { 'tag_one' }
  let(:tag_two)   { 'tag_two' }
  let(:tag_three) { 'tag_three' }

  let!(:task_one)   { create(:task, account_list: account_list, tag_list: [tag_one, tag_two]) }
  let!(:task_two)   { create(:task, account_list: account_list, tag_list: [tag_one, tag_three]) }
  let!(:task_three) { create(:task, account_list: account_list, tag_list: [tag_two, tag_three]) }

  let(:task_ids) { [task_one, task_two].map(&:id).join(', ') }

  let(:form_data) do
    {
      data: [
        {
          data: {
            type: 'tags',
            attributes: {
              name: tag_one
            }
          }
        },
        {
          data: {
            type: 'tags',
            attributes: {
              name: tag_two
            }
          }
        }
      ]
    }.merge(filter_params)
  end

  let(:filter_params) do
    {
      filter: {
        task_ids: task_ids
      }
    }
  end

  context 'authorized user' do
    before { api_login(user) }

    before do
      expect(task_one.tag_list.count).to   eq 2
      expect(task_two.tag_list.count).to   eq 2
      expect(task_three.tag_list.count).to eq 2
    end

    # create
    post '/api/v2/tasks/tags/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_create, context: self)

      example doc_helper.title_for(:bulk_create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_create)
        do_request form_data

        expect(response_status).to eq(200), invalid_status_detail

        expect(task_one.reload.tag_list.count).to   eq 2
        expect(task_two.reload.tag_list.count).to   eq 3
        expect(task_three.reload.tag_list.count).to eq 2
      end
    end

    # destroy
    delete '/api/v2/tasks/tags/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_delete, context: self)

      example doc_helper.title_for(:bulk_delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_delete)
        do_request form_data

        expect(response_status).to eq(204), invalid_status_detail

        expect(task_one.reload.tag_list.count).to   eq 0
        expect(task_two.reload.tag_list.count).to   eq 1
        expect(task_three.reload.tag_list.count).to eq 2
      end
    end
  end
end
