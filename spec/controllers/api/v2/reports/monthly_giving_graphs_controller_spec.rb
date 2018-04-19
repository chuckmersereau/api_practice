require 'rails_helper'

RSpec.describe Api::V2::Reports::MonthlyGivingGraphsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:response_json) { JSON.parse(response.body).deep_symbolize_keys }

  let(:resource) do
    Reports::MonthlyGivingGraph.new(account_list: account_list, locale: 'en')
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.id,
        month_range: "#{DateTime.new(2017, 1, 3).utc.iso8601}...#{DateTime.new(2017, 3, 3).utc.iso8601}"
      }
    }
  end

  let(:correct_attributes) { {} }

  include_examples 'show_examples', except: [:sparse_fieldsets]

  describe '#show (for a User::Coach)' do
    include_context 'common_variables'

    let(:coach) { create(:user).becomes(User::Coach) }

    before do
      account_list.coaches << coach
    end

    it 'shows resource to users that are signed in' do
      api_login(coach)
      get :show, full_params
      expect(response.status).to eq(200), invalid_status_detail
      expect(response_json[:data][:relationships][:account_list][:data][:id])
        .to eq account_list.id
      expect(response.body)
        .to include(resource.send(reference_key).to_json) if reference_key
    end

    it 'does not show resource to users that are not signed in' do
      get :show, full_params
      expect(response.status).to eq(401), invalid_status_detail
    end
  end

  describe 'Filters' do
    let!(:donor_account_1) { create(:donor_account) }
    let!(:designation_account_1) { create(:designation_account) }
    let!(:contact_1) { create(:contact, account_list: account_list) }
    let!(:donations_1) do
      create_list(:donation, 2, donor_account: donor_account_1,
                                designation_account: designation_account_1,
                                amount: 50.00,
                                donation_date: Date.today)
    end

    let!(:donor_account_2) { create(:donor_account) }
    let!(:designation_account_2) { create(:designation_account) }
    let!(:contact_2) { create(:contact, account_list: account_list) }
    let!(:donations_2) do
      create_list(:donation, 2, donor_account: donor_account_2,
                                designation_account: designation_account_2,
                                amount: 100.00,
                                donation_date: Date.today)
    end

    let!(:donor_account_3) { create(:donor_account) }
    let!(:designation_account_3) { create(:designation_account) }
    let!(:contact_3) { create(:contact, account_list: account_list) }
    let!(:donations_3) do
      create_list(:donation, 2, donor_account: donor_account_3,
                                designation_account: designation_account_3,
                                amount: 150.00,
                                donation_date: Date.today)
    end

    before do
      account_list.designation_accounts << designation_account_1
      account_list.designation_accounts << designation_account_2
      account_list.designation_accounts << designation_account_3
      contact_1.donor_accounts << donor_account_1
      contact_2.donor_accounts << donor_account_2
      contact_3.donor_accounts << donor_account_3
    end

    it 'allows a user to request all data' do
      api_login(user)
      get :show, account_list_id: account_list.id
      expect(response_json[:data][:attributes][:totals][0][:total_amount]).to eq '600.0'
    end

    it 'allows a user to filter by designation_account_id' do
      api_login(user)
      get :show, account_list_id: account_list.id, filter: { designation_account_id: designation_account_1.id }
      expect(response_json[:data][:attributes][:totals][0][:total_amount]).to eq '100.0'
    end

    it 'allows a user to filter by multiple designation_account_ids' do
      api_login(user)
      get :show,
          account_list_id: account_list.id,
          filter: { designation_account_id: "#{designation_account_1.id},#{designation_account_2.id}" }
      expect(response_json[:data][:attributes][:totals][0][:total_amount]).to eq '300.0'
    end

    it 'allows a user to filter by donor_account_id' do
      api_login(user)
      get :show, account_list_id: account_list.id, filter: { donor_account_id: donor_account_2.id }
      expect(response_json[:data][:attributes][:totals][0][:total_amount]).to eq '200.0'
    end

    it 'allows a user to filter by multiple donor_account_ids' do
      api_login(user)
      get :show,
          account_list_id: account_list.id,
          filter: { donor_account_id: "#{donor_account_1.id},#{donor_account_2.id}" }
      expect(response_json[:data][:attributes][:totals][0][:total_amount]).to eq '300.0'
    end
  end
end
