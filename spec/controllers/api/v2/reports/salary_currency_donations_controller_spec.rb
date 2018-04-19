require 'rails_helper'

RSpec.describe Api::V2::Reports::SalaryCurrencyDonationsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let(:resource) do
    Reports::SalaryCurrencyDonations.new(account_list: account_list)
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.id
      }
    }
  end

  let(:given_reference_key) { 'donor_infos' }

  include_examples 'show_examples', except: [:sparse_fieldsets]

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
      expect(response_json['data']['attributes']['donor_infos'].map { |c| c['contact_id'] }).to contain_exactly(
        contact_1.id, contact_2.id, contact_3.id
      )
    end

    it 'allows a user to filter by designation_account_id' do
      api_login(user)
      get :show, account_list_id: account_list.id, filter: { designation_account_id: designation_account_1.id }
      expect(response_json['data']['attributes']['donor_infos'].map { |c| c['contact_id'] }).to contain_exactly(
        contact_1.id
      )
    end

    it 'allows a user to filter by multiple designation_account_ids' do
      api_login(user)
      get :show,
          account_list_id: account_list.id,
          filter: { designation_account_id: "#{designation_account_1.id},#{designation_account_2.id}" }
      expect(response_json['data']['attributes']['donor_infos'].map { |c| c['contact_id'] }).to contain_exactly(
        contact_1.id, contact_2.id
      )
    end

    it 'allows a user to filter by donor_account_id' do
      api_login(user)
      get :show, account_list_id: account_list.id, filter: { donor_account_id: donor_account_2.id }
      expect(response_json['data']['attributes']['donor_infos'].map { |c| c['contact_id'] }).to contain_exactly(
        contact_2.id
      )
    end

    it 'allows a user to filter by multiple donor_account_ids' do
      api_login(user)
      get :show,
          account_list_id: account_list.id,
          filter: { donor_account_id: "#{donor_account_1.id},#{donor_account_2.id}" }
      expect(response_json['data']['attributes']['donor_infos'].map { |c| c['contact_id'] }).to contain_exactly(
        contact_1.id, contact_2.id
      )
    end
  end
end
