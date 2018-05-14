require 'rails_helper'

RSpec.describe Api::V2::TasksController, type: :controller do
  let(:user)             { create(:user_with_account) }
  let(:account_list)     { user.account_lists.order(:created_at).first }
  let(:factory_type)     { :task }
  let!(:resource)        { create(:task, account_list: account_list, start_at: 2.days.ago) }
  let!(:second_resource) { create(:task, account_list: account_list, start_at: Time.now) }
  let(:id)               { resource.id }

  let(:unpermitted_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: create(:account_list).id
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

  before do
    resource.update(tag_list: 'tag1') # Test inclusion of related resources.
  end

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  describe 'default sorting' do
    before { api_login(user) }
    let!(:resource_1) { create(:task, account_list: account_list, start_at: 1.minute.ago) }
    let!(:resource_2) { create(:task, account_list: account_list, completed: true, start_at: 4.days.ago) }
    let!(:resource_3) { create(:task, account_list: account_list, completed: true, start_at: 3.days.ago) }
    let!(:resource_4) { create(:task, account_list: account_list, start_at: 2.days.from_now) }
    let!(:resource_5) { create(:task, account_list: account_list, start_at: nil) }

    it 'orders results by completed and start_at' do
      get :index

      ids = response_json['data'].map { |obj| obj['id'] }
      expect(ids).to eq [
        resource_1.id, resource.id, second_resource.id, resource_4.id, resource_5.id, resource_3.id, resource_2.id
      ]
    end
  end

  describe 'filtering' do
    before { api_login(user) }

    FILTERS = (
      Task::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore) +
      Task::Filterer::FILTERS_TO_HIDE.collect(&:underscore)
    )

    FILTERS.each do |filter|
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
        get :index, filter: { account_list_id: account_list_two.id }

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data'].length).to eq(1)
      end
    end
  end
end
