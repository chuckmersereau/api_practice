require 'spec_helper'
require 'json'

describe Api::V2::AccountLists::FiltersController, type: :controller do
  let(:factory_type) { 'account-lists' }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  context 'authorized user' do
    before do
      api_login(user)
    end

    describe '#index' do
      it 'gets filters for contacts and tasks' do
        get :index, account_list_id: account_list_id, contact: 1, task: 1
        expect(JSON.parse(response.body).keys).to eq %w(contact_filters task_filters)
        expect(response.status).to eq 200
      end

      it 'gets filters for contacts' do
        get :index, account_list_id: account_list_id, contact: 1
        expect(JSON.parse(response.body).keys).to eq %w(contact_filters)
        expect(response.status).to eq 200
      end

      it 'gets filters for tasks' do
        get :index, account_list_id: account_list_id, task: 1
        expect(JSON.parse(response.body).keys).to eq %w(task_filters)
        expect(response.status).to eq 200
      end

      it 'does not get filters' do
        get :index, account_list_id: account_list_id
        expect(JSON.parse(response.body).keys).to eq %w()
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
