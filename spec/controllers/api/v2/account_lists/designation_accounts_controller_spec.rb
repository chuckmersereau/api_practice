require 'rails_helper'

describe Api::V2::AccountLists::DesignationAccountsController, type: :controller do
  let(:factory_type) { :designation_account }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let!(:designation_account) { create(:designation_account, account_lists: [account_list]) }
  let!(:second_designation_account) do
    create(:designation_account, account_lists: [account_list], created_at: 1.day.from_now)
  end
  let(:id) { designation_account.id }

  let(:resource) { designation_account }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:designation_account) }

  include_examples 'index_examples'

  include_examples 'show_examples'

  describe '#index' do
    before { api_login(user) }
    describe 'filter[wildcard_search]' do
      context 'designation_number starts with' do
        let!(:designation_account) { create(factory_type, designation_number: '1234', account_lists: [account_list]) }
        it 'returns designation_account' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: '12' }
          expect(JSON.parse(response.body)['data'][0]['id']).to eq(designation_account.id)
        end
      end
      context 'designation_number does not start with' do
        let!(:designation_account) { create(factory_type, designation_number: '1234', account_lists: [account_list]) }
        it 'returns no designation_accounts' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: '34' }
          expect(JSON.parse(response.body)['data'].count).to eq(0)
        end
      end
      context 'name contains' do
        let!(:donor_account) { create(factory_type, name: 'abcd', account_lists: [account_list]) }
        it 'returns designation_account' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: 'bc' }
          expect(JSON.parse(response.body)['data'][0]['id']).to eq(donor_account.id)
        end
      end
      context 'name does not contain' do
        let!(:donor_account) { create(factory_type, name: 'abcd', account_lists: [account_list]) }
        it 'returns no designation_accounts' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: 'def' }
          expect(JSON.parse(response.body)['data'].count).to eq(0)
        end
      end
    end
  end
end
