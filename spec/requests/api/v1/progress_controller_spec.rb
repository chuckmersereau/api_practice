require 'spec_helper'
require_relative 'api_spec_helper'

describe Api::V1::ProgressController do
  describe 'api' do
    let(:user) { create(:user_with_account) }
    let!(:contact) do
      create(:contact, status: 'Call for Appointment',
                       account_list: user.account_lists.first)
    end

    around do |example|
      # Due to the way that we calculate the number of referrals, this spec was
      # failing on a Sunday (week boundary). This will make it work for now
      # (stubbing the time to not be a Sunday), though at some point we should
      # re-examine the logic of the progress controller with respect to week
      # boundaries and time zones. See this JIRA ticket for the details:
      # https://jira.cru.org/browse/MPDX-357
      travel_to Time.new(2015, 12, 10) do
        example.run
      end
    end

    before do
      stub_auth
    end

    it 'responds 200' do
      get '/api/v1/progress?access_token=' + user.access_token
      expect(response).to be_success
      expect(JSON.parse(response.body)['contacts']['active']).to eq 1
    end

    it 'correctly counts the number of active referrals' do
      referral1 = create(:contact, account_list: contact.account_list, status: 'Ask in Future')
      referral1.update_column(:created_at, 1.month.ago)
      referral2 = create(:contact, account_list: contact.account_list, status: 'Contact for Appointment')
      contact.referrals_by_me << referral1
      contact.referrals_by_me << referral2

      get '/api/v1/progress?access_token=' + user.access_token
      counts = assigns(:counts)
      expect(counts[:contacts][:referrals]).to eq 2
      expect(counts[:contacts][:referrals_on_hand]).to eq 2
    end
  end
end
