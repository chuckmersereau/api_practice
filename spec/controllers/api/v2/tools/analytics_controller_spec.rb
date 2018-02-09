require 'rails_helper'

RSpec.describe Api::V2::Tools::AnalyticsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:second_account_list) { create(:account_list, users: [user]) }

  let!(:contact_one) { create(:contact, account_list: account_list, status_valid: false) }
  let!(:contact_two) { create(:contact, account_list: account_list) }

  let(:resource) do
    Tools::Analytics.new(
      account_lists: [account_list]
    )
  end

  let(:given_reference_key) { 'counts_by_type' }

  include_examples 'show_examples', except: [:sparse_fieldsets]

  context 'filtering by account_list_id' do
    let(:full_params) do
      {
        filter: {
          account_list_id: second_account_list.id
        }
      }
    end

    it 'filters out other account_lists' do
      api_login(user)
      get :show, full_params
      expect(response.status).to eq(200)
      expect(response.body).to_not include(account_list.id)
    end
  end
end
