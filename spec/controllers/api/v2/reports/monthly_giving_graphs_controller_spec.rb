require 'rails_helper'

RSpec.describe Api::V2::Reports::MonthlyGivingGraphsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:response_json) { JSON.parse(response.body).deep_symbolize_keys }

  let(:resource) do
    Reports::MonthlyGivingGraph.new(account_list: account_list, locale: 'en')
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.uuid,
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
        .to eq account_list.uuid
      expect(response.body)
        .to include(resource.send(reference_key).to_json) if reference_key
    end

    it 'does not show resource to users that are not signed in' do
      get :show, full_params
      expect(response.status).to eq(401), invalid_status_detail
    end
  end
end
