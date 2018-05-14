require 'rails_helper'

RSpec.describe Api::V2::Reports::PledgeHistoriesController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let(:given_serializer_class) { Reports::PledgeHistoriesPeriodSerializer }
  let(:given_resource_type) { 'reports_pledge_histories_periods' }
  let(:factory_type) { :account_list }
  let(:resource) do
    Reports::PledgeHistoriesPeriod.new(
      account_list: account_list, start_date: 1.week.ago, end_date: DateTime.now
    )
  end

  let(:correct_attributes) { {} }

  include_examples 'index_examples', except: [:sorting, :pagination]

  describe 'Filters' do
    it 'allows a user to request from their account_list' do
      api_login(user)
      get :index, filter: { account_list_id: account_list.id }
      expect(response.status).to eq 200
    end

    it 'blocks a user from accessing others account lists' do
      api_login(create(:user))
      get :index, filter: { account_list_id: account_list.id }
      expect(response.status).to eq 404
    end
  end
end
