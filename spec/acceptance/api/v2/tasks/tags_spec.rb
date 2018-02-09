require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tasks > Tags' do
  include_context :json_headers
  documentation_scope = :tasks_api_tags

  let(:resource_type) { 'tags' }
  let!(:user)         { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task)   { create(:task, account_list: account_list) }
  let(:task_id) { task.id }

  let(:tag_name) { 'new_tag' }

  let(:new_tag_params) { { name: tag_name } }
  let(:form_data)      { build_data(new_tag_params) }

  before { api_login(user) }

  get '/api/v2/tasks/tags' do
    let!(:account_list_two) { create(:account_list) }
    let!(:task_one) { create(:task, account_list: account_list, tag_list: [tag_name]) }
    let!(:task_two) { create(:task, account_list: account_list_two, tag_list: [tag_name]) }
    before { user.account_lists << account_list_two }
    example 'Tag [LIST]', document: documentation_scope do
      explanation 'List Task Tags'
      do_request
      expect(resource_data.count).to eq 1
      expect(first_or_only_item['type']).to eq 'tags'
      expect(resource_object.keys).to match_array(%w(name))
      expect(response_status).to eq 200
    end
  end

  post '/api/v2/tasks/:task_id/tags' do
    with_options scope: [:data, :attributes] do
      parameter 'name', 'Name of Tag'
    end

    example 'Tag [CREATE]', document: documentation_scope do
      explanation 'Create a Tag associated with the Task'
      do_request data: form_data
      expect(resource_object['new_tag']).to eq new_tag_params['new_tag']
      expect(response_status).to eq 201
    end
  end

  delete '/api/v2/tasks/:task_id/tags/:tag_name' do
    parameter 'tag_name', 'The name of the tag'
    parameter 'task_id',  'The Task ID of the Tag'

    example 'Tag [DELETE]', document: documentation_scope do
      explanation 'Delete the Task\'s Tag with the given name'
      do_request
      expect(response_status).to eq 204
    end
  end
end
