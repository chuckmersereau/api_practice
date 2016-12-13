require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Tags' do
  include_context :json_headers

  let(:resource_type) { 'tasks' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:task)   { create(:task, account_list: user.account_lists.first) }
  let(:task_id) { task.id }

  let(:tag_name) { 'new_tag' }

  let(:new_tag_params) { { name: tag_name } }
  let(:form_data)      { build_data(new_tag_params) }

  before { api_login(user) }

  post '/api/v2/tasks/:task_id/tags' do
    with_options scope: [:data, :attributes] do
      parameter 'name', 'Name of Tag'
    end

    example 'Tag [CREATE]', document: :tasks do
      explanation 'Create a Tag associated with the Task'
      do_request data: form_data
      expect(resource_object['new_tag']).to eq new_tag_params['new_tag']
      expect(response_status).to eq 201
    end
  end

  delete '/api/v2/tasks/:task_id/tags/:tag_name' do
    parameter 'tag_name', 'The name of the tag'
    parameter 'task_id',  'The Task ID of the Tag'

    example 'Tag [DELETE]', document: :tasks do
      explanation 'Delete the Task\'s Tag with the given name'
      do_request
      expect(response_status).to eq 204
    end
  end
end
