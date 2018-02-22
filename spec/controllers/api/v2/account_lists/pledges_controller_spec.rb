require 'rails_helper'

RSpec.describe Api::V2::AccountLists::PledgesController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:contact) { create(:contact, account_list: account_list) }

  # This is required!
  let(:factory_type) { :pledge }

  # This is required!
  let!(:resource) do
    create(:pledge, account_list: account_list, contact: contact, amount: 9.99)
  end

  # This is required for the index action!
  let!(:second_resource) do
    create(:pledge, account_list: account_list, amount: 10.00)
  end

  # If needed, keep this ;)
  let(:id) { resource.id }

  # If needed, keep this ;)
  let(:parent_param) do
    { account_list_id: account_list.id }
  end

  # This is required!
  let(:correct_attributes) do
    { amount: 200.00, amount_currency: 'USD', expected_date: Date.today }
  end

  let(:correct_relationships) do
    {
      contact: {
        data: {
          id: contact.id,
          type: 'contacts'
        }
      }
    }
  end

  # This is required!
  let(:unpermitted_relationships) do
    {
      contact: {
        data: {
          id: create(:contact).id,
          type: 'contacts'
        }
      }
    }
  end

  # This is required!
  let(:incorrect_attributes) do
    { amount: 200.00, expected_date: nil }
  end

  # These includes can be found in:
  # spec/support/shared_controller_examples/*
  include_examples 'index_examples'

  describe 'sort' do
    before { api_login(user) }

    let(:contact2) { create(:contact, account_list: account_list, name: 'zzzzz') }
    let!(:pledge3) { create(:pledge, account_list: account_list, contact: contact2, amount: 10.00) }

    it 'sorts results by contact.name desc' do
      get :index, parent_param.merge(sort: 'contact.name')

      json = JSON.parse(response.body)
      ids = json['data'].collect { |pledge| pledge['id'] }
      expect(ids.last).to eq pledge3.id
    end

    it 'sorts results by contact.name asc' do
      get :index, parent_param.merge(sort: '-contact.name')

      json = JSON.parse(response.body)
      ids = json['data'].collect { |pledge| pledge['id'] }
      expect(ids.first).to eq pledge3.id
    end
  end

  describe 'filtering' do
    before { api_login(user) }

    context 'status filter' do
      let(:contact2) { create(:contact, account_list: account_list) }
      let!(:pledge3) { create(:pledge, account_list: account_list, contact: contact2, amount: 10.00, status: :processed) }

      it 'filters results' do
        get :index, parent_param.merge(filter: { status: 'processed' })

        expect(response.status).to eq(200)
        expect(response_json['data'].length).to eq(1)
        expect(response_json['data'][0]['id']).to eq(pledge3.id)
      end
    end
  end

  include_examples 'show_examples'

  context 'with no existing Pledges' do
    before { Pledge.destroy_all }
    include_examples 'create_examples'
  end

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
