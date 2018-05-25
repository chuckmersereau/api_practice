require 'rails_helper'

RSpec.describe Api::V2::AccountLists::PledgesController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:factory_type) { :pledge }
  let!(:resource) do
    create(:pledge,
           account_list: account_list,
           contact: contact,
           amount: 9.99,
           expected_date: 1.month.ago)
  end
  let!(:second_resource) do
    create(:pledge,
           account_list: account_list,
           amount: 10.00,
           expected_date: 2.months.from_now)
  end
  let(:id) { resource.id }
  let(:parent_param) do
    { account_list_id: account_list.id }
  end
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
  let(:incorrect_attributes) do
    { amount: 200.00, expected_date: nil }
  end

  include_examples 'index_examples'
  include_examples 'show_examples'
  include_examples 'update_examples'
  include_examples 'destroy_examples'

  describe 'sort' do
    before { api_login(user) }

    let(:contact_2) { create(:contact, account_list: account_list, name: 'zzzzz') }
    let!(:pledge_3) { create(:pledge, account_list: account_list, contact: contact_2, amount: 10.00) }

    it 'sorts results by contact.name desc' do
      get :index, parent_param.merge(sort: 'contact.name')

      json = JSON.parse(response.body)
      ids = json['data'].collect { |pledge| pledge['id'] }
      expect(ids.last).to eq pledge_3.id
    end

    it 'sorts results by contact.name asc' do
      get :index, parent_param.merge(sort: '-contact.name')

      json = JSON.parse(response.body)
      ids = json['data'].collect { |pledge| pledge['id'] }
      expect(ids.first).to eq pledge_3.id
    end
  end

  describe 'filtering' do
    before { api_login(user) }

    context 'status filter' do
      let(:contact_2) { create(:contact, account_list: account_list) }
      let!(:pledge_3) do
        create(:pledge, account_list: account_list, contact: contact_2, amount: 10.00, status: :processed)
      end

      it 'filters results' do
        get :index, parent_param.merge(filter: { status: 'processed' })

        expect(response.status).to eq(200)
        expect(response_json['data'].length).to eq(1)
        expect(response_json['data'][0]['id']).to eq(pledge_3.id)
      end
    end
  end

  context 'with no existing Pledges' do
    before { Pledge.destroy_all }
    include_examples 'create_examples'
  end

  context 'User::Coach' do
    include_context 'common_variables'

    let(:coach) { create(:user).becomes(User::Coach) }

    before do
      account_list.coaches << coach
      full_params[:include] = 'contact'
    end

    describe '#index' do
      it 'shows list of resources to coach that are signed in' do
        api_login(coach)
        get :index, full_params
        expect(response.status).to eq(200), invalid_status_detail
        expect(json_response['data'].count).to eq 1
        expect(json_response['data'][0]['id']).to eq resource.id
        expect(json_response['data'][0]['attributes'].keys).to eq(
          %w(amount created_at expected_date updated_at updated_in_db_at)
        )
        expect(json_response['data'][0]['relationships'].keys).to eq(
          %w(contact)
        )
        expect(json_response['included'].count).to eq 1
        expect(json_response['included'][0]['id']).to eq resource.contact.id
        expect(json_response['included'][0]['attributes'].keys).to eq(
          %w(created_at late_at locale name pledge_amount pledge_currency pledge_currency_symbol
             pledge_frequency pledge_received pledge_start_date updated_at updated_in_db_at)
        )
      end

      it 'only shows records that are on primary appeal' do
        resource.update(appeal: create(:appeal, account_list: account_list))

        api_login(coach)
        get :index, full_params
        expect(response.status).to eq(200), invalid_status_detail
        expect(json_response['data'].count).to eq 0
      end

      it 'does not show list of resources to users that are not signed in' do
        get :index, full_params
        expect(response.status).to eq(401), invalid_status_detail
      end
    end

    describe '#create' do
      it 'does not create resource for users that are only coaches' do
        post :create, full_correct_attributes
        expect(response.status).to eq(401), invalid_status_detail
      end
    end

    describe '#update' do
      it 'does not create resource for users that are only coaches' do
        put :update, full_correct_attributes
        expect(response.status).to eq(401), invalid_status_detail
      end
    end

    describe '#destroy' do
      it 'does not create resource for users that are only coaches' do
        delete :destroy, full_correct_attributes
        expect(response.status).to eq(401), invalid_status_detail
      end
    end
  end
end
