require 'rails_helper'
require 'json'

describe Api::V2::Contacts::FiltersController, type: :controller do
  let(:factory_type) { 'account_lists' }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  context 'authorized user' do
    before do
      api_login(user)
    end

    describe '#index' do
      it 'gets filters for contacts' do
        get :index
        filters_displayed = JSON.parse(response.body)['data'].map do |filter|
          filter['type'].gsub('contact_filter_', '').camelize
        end
        expect(Contact::Filterer::FILTERS_TO_DISPLAY.map(&:pluralize)).to include(*filters_displayed)
        expect(response.status).to eq 200
      end
    end
  end

  context 'unauthorized user' do
    describe '#index' do
      it 'does not get a list of filters' do
        get :index, account_list_id: account_list_id
        expect(response.status).to eq 401
      end
    end
  end
end
