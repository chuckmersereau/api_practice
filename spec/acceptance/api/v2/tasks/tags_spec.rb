require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Google Accounts' do
  let(:resource_type) { 'tasks' }
  let!(:user) { create(:user_with_full_account) }
  let!(:task) { create(:task, account_list: user.account_lists.first) }
  let(:task_id) { task.id }
  let(:tag_name) { 'new_tag' }
  let(:new_tag_params) { { name: tag_name } }
  let(:form_data) { build_data(new_tag_params) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    post '/api/v2/tasks/:task_id/tags' do
      with_options scope: [:data, :attributes] do
        parameter :name, 'name of Tag'
      end

      example 'create tag' do
        do_request data: form_data
        expect(resource_object['new_tag']).to eq new_tag_params['new_tag']
        expect(status).to eq 200
      end
    end

    delete '/api/v2/tasks/:task_id/tags/:tag_name' do
      parameter :task_id, 'the Task id of the Google Account'
      parameter :tag_name, 'the Id of the Google Account'

      example_request 'delete tag' do
        expect(status).to eq 200
      end
    end
  end
end
