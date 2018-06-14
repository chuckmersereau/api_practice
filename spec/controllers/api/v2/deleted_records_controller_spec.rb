require 'rails_helper'

describe Api::V2::DeletedRecordsController, type: :controller do
  let(:factory_type) { :deleted_record }
  # first user
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let!(:resource) { create(:deleted_record, account_list: account_list, deleted_by: user, deleted_at: Date.today - 1.day) }
  let!(:second_resource) { create(:deleted_record, account_list: account_list, deleted_by: user, deleted_at: Date.today - 1.day) }
  let!(:third_resource) { create(:deleted_record, account_list: account_list, deleted_by: user, deleted_at: Date.today - 2.years) }
  let!(:fourth_resource) { create(:deleted_record, account_list: account_list, deleted_by: user, deleted_at: Time.zone.now) }
  let!(:second_deleted_task_record) do
    create(:deleted_task_record, account_list: account_list, deleted_by: user, deleted_at: Date.today - 2.years)
  end

  # second user
  let!(:second_user) { create(:user_with_account) }
  let!(:second_account_list) { second_user.account_lists.order(:created_at).first }
  let!(:deleted_task_record) do
    create(:deleted_task_record, account_list: second_account_list, deleted_by: user, deleted_at: Date.today - 1.day)
  end

  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:deleted_record, account_list: account_list, deleted_by: user) }
  let(:incorrect_attributes) { attributes_for(:deleted_record, account_list: nil) }

  context 'get all deleted records' do
    it 'that have been created by a specific time' do
      api_login(user)
      get :index, filter: { since_date: Date.current.beginning_of_year }
      data = JSON.parse(response.body)['data']

      expect(data.size).to eq(3)
    end

    it 'should only get deleted records that are Contacts' do
      api_login(user)
      get :index, filter: { types: 'Contact' }
      data = JSON.parse(response.body)['data']
      expect(data.size).to eq(4)
      data.each do |hash|
        expect(hash['attributes']['deletable_type']).to eq('Contact')
      end
    end

    it 'should only get deleted records that are Tasks' do
      api_login(user)
      get :index, filter: { types: 'Activity' }
      data = JSON.parse(response.body)['data']
      expect(data.size).to eq(1)
      data.each do |hash|
        expect(hash['attributes']['deletable_type']).to eq('Activity')
      end
    end

    it 'should get all Task and Contact records' do
      api_login(user)
      get :index, filter: { types: %w(Contact Activity) }
      data = JSON.parse(response.body)['data']
      expect(data.size).to eq(5)
    end

    it 'should get Task records for a specific period' do
      api_login(user)
      start_date = Date.current.beginning_of_year - 2.years
      get :index, filter: { types: 'Activity', since_date: "#{start_date}..#{Date.current}" }
      data = JSON.parse(response.body)['data']
      expect(data.size).to eq(1)
    end

    it 'should get all records for an account list id' do
      api_login(user)
      get :index
      data = JSON.parse(response.body)['data']
      expect(data.size).to eq(5)
    end
  end
end
