require 'rails_helper'

describe Api::V2::Coaching::ContactsController, type: :controller do
  let(:given_serializer_class) { Coaching::ContactSerializer }
  let(:resource_type) { 'contacts' }
  let(:factory_type) { :contact }
  let!(:user) { create(:user, locale: :en) }

  let!(:owner) { create(:user_with_account) }
  let!(:account_list) { owner.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let!(:contact_1) { create :contact, account_list_id: account_list.id }
  let!(:contact_2) { create :contact, account_list_id: account_list.id, created_at: 1.week.from_now }
  let!(:contact_3) { create :contact, created_at: 2.weeks.from_now }
  let(:id) { contact_1.id }

  let!(:coaches) { create_list(:user_coach, 2) }
  before do
    account_list.coaches += coaches
    account_list.coaches << user.becomes(User::Coach)
  end

  let(:resource) { contact_1 }
  let(:correct_attributes) { attributes_for(:contact) }

  include_examples 'index_examples'
  include_examples 'show_examples'

  describe 'hash[total_pledge]' do
    before do
      contact_1.update(pledge_amount: 100, pledge_frequency: 4)
      contact_2.update(pledge_amount: 200, pledge_frequency: 1)
      contact_3.update(pledge_amount: 999, pledge_frequency: 1)
    end

    it 'totals the contacts\' commitment in the "meta" object' do
      api_login(user)

      get :index, parent_param_if_needed
      expect(response.status).to eq(200), invalid_status_detail

      meta = JSON.parse(response.body)['meta']
      expect(meta['total_pledge']['amount']).to eq(100 / 4 + 200 / 1)
      expect(meta['total_pledge']['currency']).to eq('USD')
    end
  end
end
