require 'spec_helper'
require 'json'

describe Api::V2::Tasks::FiltersController, type: :controller do
  let!(:user) { create(:user_with_account) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    describe '#index' do
      it 'gets filters for tasks' do
        get :index
        filters_displayed = JSON.parse(response.body)['data'].map do |filter|
          filter['type'].gsub('task_filter_', '').camelize
        end
        expect(Task::Filterer::FILTERS_TO_DISPLAY.map(&:pluralize)).to include(*filters_displayed)
        expect(response.status).to eq 200
      end
    end
  end

  context 'unauthorized user' do
    describe '#index' do
      it 'does not get a list of filters' do
        get :index
        expect(response.status).to eq 401
      end
    end
  end
end
