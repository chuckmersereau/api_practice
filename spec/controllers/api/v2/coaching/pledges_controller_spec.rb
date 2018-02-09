require 'rails_helper'

describe Api::V2::Coaching::PledgesController, type: :controller do
  let(:resource_type) { 'pledges' }
  let(:factory_type) { :pledge }
  let(:user) { create(:user, locale: :en) }

  let(:owner) { create(:user_with_account) }
  let(:account_list) { owner.account_lists.first }

  let(:contact) { create :contact, account_list: account_list }
  let(:appeal) { create :appeal, account_list: account_list }

  let!(:pledge_1) { create_pledge amount: 20, expected_date: 2.days.from_now }
  let!(:pledge_2) { create_pledge amount: 30, expected_date: 3.days.from_now }
  let!(:pledge_3) { create_pledge amount: 40, expected_date: 4.days.from_now }

  let(:id) { pledge_1.id }

  let!(:coaches) { create_list(:user_coach, 2) }
  before do
    account_list.coaches += coaches
    account_list.coaches << user.becomes(User::Coach)
  end

  let(:resource) { pledge_1 }
  let(:correct_attributes) { attributes_for(:pledge) }

  include_examples 'index_examples'
  include_examples 'show_examples'

  describe 'hash[total_pledge]' do
    before do
      pledge_1.update(amount: 100)
      pledge_2.update(amount: 200)
      pledge_3.update(amount: 999, account_list: create(:account_list))
    end

    it 'totals the pledges\' commitment in the "meta" object' do
      api_login(user)

      get :index, parent_param_if_needed
      expect(response.status).to eq(200), invalid_status_detail

      meta = JSON.parse(response.body)['meta']
      expect(meta['total_pledge']['amount']).to eq 300
      expect(meta['total_pledge']['currency']).to eq 'USD'
    end
  end

  private

  def create_pledge(args = {})
    create :pledge, args.merge(appeal: appeal, account_list: account_list)
  end
end
