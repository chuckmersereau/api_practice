require 'rails_helper'

RSpec.describe Api::V2::Contacts::ChurchNamesController, type: :controller do
  let(:resource_type) { :churches }
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let(:second_user) { create(:user_with_account) }
  let(:second_account_list) { second_user.account_lists.order(:created_at).first }

  let(:church_name) { 'Beautiful Saviour' }
  let(:second_church_name) { 'Cross of Christ' }
  let(:third_church_name) { 'Calvary Chapel' }

  let!(:contact) { create(:contact, account_list: account_list, church_name: church_name) }
  let!(:second_contact) { create(:contact, account_list: account_list, church_name: second_church_name) }
  let!(:third_contact) { create(:contact, account_list: second_account_list, church_name: third_church_name) }

  let(:correct_attributes) { { church_name: church_name } }
  let(:incorrect_attributes) { { church_name: nil } }

  describe '#index' do
    it 'returns the list of church names for all the users contacts' do
      api_login(user)
      get :index
      data = ::JSON.parse(response.body)['data']
      expect(data.size).to eq(2)
      expect(data[0]['attributes']['church_name']).to eq(church_name)
      expect(data[1]['attributes']['church_name']).to eq(second_church_name)
    end

    it 'only returns the users contacts church names' do
      api_login(second_user)
      get :index
      data = ::JSON.parse(response.body)['data']
      expect(data.size).to eq(1)
      expect(data[0]['attributes']['church_name']).to eq(third_church_name)
    end

    it 'will search for similar church names' do
      api_login(user)
      get :index, filter: { church_name_like: 'saviour' }
      data = ::JSON.parse(response.body)['data']
      expect(data.size).to eq(1)
      expect(data[0]['attributes']['church_name']).to eq(church_name)
    end
  end
end
