require 'rails_helper'

describe Api::V2::AccountListsController, type: :controller do
  let(:factory_type) { :account_list }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let!(:second_account_list) { create(:account_list, users: [user], created_at: 2.weeks.from_now) }
  let(:id) { account_list.id }

  let(:resource) { account_list }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:account_list) }
  let(:incorrect_attributes) { { name: nil } }

  let!(:notification_preference) { create(:notification_preference, account_list: account_list) }

  let(:correct_relationships) do
    {
      notification_preferences: {
        data: {
          type: 'notification_preferences',
          id: create(:notification_preference).id
        }
      }
    }
  end

  include_examples 'index_examples'
  include_examples 'show_examples'
  include_examples 'update_examples'

  context 'User::Coach' do
    include_context 'common_variables'

    let(:contact) { create(:contact, account_list: account_list) }
    let!(:pledge) do
      create(:pledge,
             account_list: account_list,
             contact: contact,
             amount: 9.99,
             expected_date: 1.month.ago)
    end
    let!(:second_pledge) do
      create(:pledge,
             account_list: account_list,
             amount: 10.00,
             expected_date: 2.months.from_now)
    end
    let!(:appeal) { create(:appeal, account_list: account_list) }
    let(:coach) { create(:user).becomes(User::Coach) }

    before do
      pledge.update(appeal: appeal)
      account_list.coaches << coach
      account_list.update(primary_appeal_id: appeal.id)
    end

    describe '#show' do
      it 'shows list of resources to the coach who is signed in' do
        api_login(coach)
        get :show, full_params
        expect(response.status).to eq(200), invalid_status_detail
        expect(json_response['data']['attributes']['primary_appeal']).to_not be_nil
        %w(balance committed currency monthly_goal primary_appeal progress received total_pledges).each do |key|
          expect(json_response['data']['attributes']).to have_key(key)
        end
      end
    end
  end
end
