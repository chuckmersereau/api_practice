require 'rails_helper'

describe Api::V2::AccountLists::DonorAccountsController, type: :controller do
  let(:factory_type) { :donor_account }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:contact2) { create(:contact, account_list: account_list) }
  let!(:donor_accounts) { create_list(:donor_account, 3) }
  let(:donor_account) { donor_accounts.first }
  let(:id) { donor_account.uuid }

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

    it 'shows donor accounts from selected contacts' do
      api_login(user)
      create(factory_type)
      get :index, account_list_id: account_list_id, filter: { contacts: [contact] }
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['data'].count).to eq(2)
    end

    it "doesn't include contacts from different account_list" do
      api_login(user)
      create(factory_type, contacts: [contact_one, contact_two])
      get :index, account_list_id: account_list_id, include: '*'
      expect(response.status).to eq(200)
      expect(included_array_in_response.any? { |resource| resource['id'] == contact_two.uuid }).to eq(false)
    end
  end
end
