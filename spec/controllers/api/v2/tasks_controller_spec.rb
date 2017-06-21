require 'rails_helper'

RSpec.describe Api::V2::TasksController, type: :controller do
  let(:user)             { create(:user_with_account) }
  let(:account_list)     { user.account_lists.first }
  let(:factory_type)     { :task }
  let!(:resource)        { create(:task, account_list: account_list) }
  let!(:second_resource) { create(:task, account_list: account_list) }
  let(:id)               { resource.uuid }

  let(:unpermitted_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: create(:account_list).uuid
        }
      }
    }
  end

  let(:correct_attributes) do
    {
      subject: 'test subject',
      start_at: Time.now,
      tag_list: 'tag1'
    }
  end

  let(:unpermitted_attributes) do
    {
      subject: 'test subject',
      start_at: Time.now
    }
  end

  let(:incorrect_attributes) do
    {
      subject: nil
    }
  end
  let(:sorting_param) { :completed_at }

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

    FILTERS = (
      Task::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore) +
      Task::Filterer::FILTERS_TO_HIDE.collect(&:underscore)
    )

    FILTERS.each_with_index do |filter|
      context "#{filter} filter" do
        let(:value) { filter == 'updated_at' ? Date.today.to_s : '' }

        it 'filters results' do
          get :index, filter: { filter => value }
          expect(response.status).to eq(200), invalid_status_detail

          expect(JSON.parse(response.body)['meta']['filter'][filter]).to eq(value)
        end
      end
    end

    context 'account_list_id filter' do
      let!(:user)             { create(:user_with_account) }
      let!(:account_list_two) { create(:account_list) }
      let!(:task_two)         { create(:task, account_list: account_list_two) }

      before { user.account_lists << account_list_two }

      it 'filters results' do
        get :index, filter: { account_list_id: account_list_two.uuid }

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data'].length).to eq(1)
      end
    end
  end
end
