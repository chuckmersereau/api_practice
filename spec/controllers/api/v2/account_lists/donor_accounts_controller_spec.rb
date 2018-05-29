require 'rails_helper'

describe Api::V2::AccountLists::DonorAccountsController, type: :controller do
  let(:factory_type) { :donor_account }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:contact2) { create(:contact, account_list: account_list) }
  let!(:donor_accounts) { create_list(:donor_account, 3) }
  let(:donor_account) { donor_accounts.first }
  let(:id) { donor_account.id }

  before do
    contact.donor_accounts << donor_accounts[0]
    contact.donor_accounts << donor_accounts[1]
    contact2.donor_accounts << donor_accounts[2]
  end

  let(:resource) { donor_account }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:donor_account) }

  include_examples 'index_examples'

  include_examples 'show_examples'

  describe '#index' do
    let(:contact_one) { create(:contact, account_list: account_list) }
    let(:contact_two) { create(:contact) }
    let(:included_array_in_response) { JSON.parse(response.body)['included'] }
    before { api_login(user) }

    it 'shows donor accounts from selected contacts' do
      create(factory_type)
      get :index, account_list_id: account_list_id, filter: { contacts: [contact] }
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['data'].count).to eq(2)
    end

    it "doesn't include contacts from different account_list" do
      create(factory_type, contacts: [contact_one, contact_two])
      get :index, account_list_id: account_list_id, include: '*'
      expect(response.status).to eq(200)
      expect(included_array_in_response.any? { |resource| resource['id'] == contact_two.id }).to eq(false)
    end

    describe 'filter[wildcard_search]' do
      context 'account_number starts with' do
        let!(:donor_account) { create(factory_type, account_number: '1234') }
        before { contact.donor_accounts << donor_account }
        it 'returns donor_account' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: '12' }
          expect(JSON.parse(response.body)['data'][0]['id']).to eq(donor_account.id)
        end
      end
      context 'account_number does not start with' do
        let!(:donor_account) { create(factory_type, account_number: '1234') }
        before { contact.donor_accounts << donor_account }
        it 'returns donor_accounts' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: '34' }
          expect(JSON.parse(response.body)['data'].count).to eq(1)
        end
      end
      context 'name contains' do
        let!(:donor_account) { create(factory_type, name: 'abcd') }
        before { contact.donor_accounts << donor_account }
        it 'returns dnor_account' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: 'bc' }
          expect(JSON.parse(response.body)['data'][0]['id']).to eq(donor_account.id)
        end
      end
      context 'name does not contain' do
        let!(:donor_account) { create(factory_type, name: 'abcd') }
        before { contact.donor_accounts << donor_account }
        it 'returns no donor_accounts' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: 'def' }
          expect(JSON.parse(response.body)['data'].count).to eq(0)
        end
      end
    end
  end
end
