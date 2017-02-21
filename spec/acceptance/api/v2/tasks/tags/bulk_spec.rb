require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Bulks' do
  include_context :json_headers

  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:tag_name) { 'tag_one' }
  let(:task_one) { create(:task, account_list: account_list, tag_list: [tag_name]) }
  documentation_scope = :tasks

  context 'authorized user' do
    before { api_login(user) }

    # destroy
    delete '/api/v2/tasks/tags/bulk' do
      parameter :tag_name, 'Name of tag to delete'
      example 'Tag [DELETE] [BULK]', document: documentation_scope do
        explanation 'Delete a Tag from all Tasks'
        expect do
          do_request
        end.to change { task_one.reload.tag_list.length }.by(-1)
        expect(response_status).to eq 204
      end
    end
  end
end
