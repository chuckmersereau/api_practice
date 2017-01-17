require 'spec_helper'

RSpec.describe Api::V2::TasksController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :task }
  let!(:resource) { create(:task, account_list: account_list) }
  let!(:second_resource) { create(:task, account_list: account_list) }
  let(:id) { resource.uuid }
  let(:correct_attributes) { { subject: 'test subject', start_at: Time.now, account_list_id: account_list.uuid, tag_list: 'tag1' } }
  let(:unpermitted_attributes) { { subject: 'test subject', start_at: Time.now, account_list_id: create(:account_list).uuid } }
  let(:incorrect_attributes) { { subject: nil, account_list_id: account_list.uuid } }

  before do
    resource.update(tag_list: 'tag1') # Test inclusion of related resources.
  end

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  describe 'filtering' do
    before { api_login(user) }
    (Task::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore) + Task::Filterer::FILTERS_TO_HIDE.collect(&:underscore)).each do |filter|
      context "#{filter} filter" do
        it 'filters results' do
          get :index, filter: { filter => '' }
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)['meta']['filter'][filter]).to eq('')
        end
      end
    end

    context 'account_list_id filter' do
      let!(:user) { create(:user_with_account) }
      let!(:account_list_two) { create(:account_list) }
      let!(:task_two) { create(:task, account_list: account_list_two) }
      before { user.account_lists << account_list_two }
      it 'filters results' do
        get :index, filter: { account_list_id: account_list_two.uuid }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data'].length).to eq(1)
      end
    end
  end
end
