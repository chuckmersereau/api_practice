require 'spec_helper'
require_relative 'api_spec_helper'

describe Api::V1::ProgressController do
  describe 'api' do
    let(:user) { create(:user_with_account) }
    let!(:contact) do
      create(:contact, status: 'Call for Appointment',
                       account_list: user.account_lists.first)
    end

    before do
      stub_auth
      get '/api/v1/progress?access_token=' + user.access_token
    end

    it 'responds 200' do
      response.code.should == '200'
      expect(JSON.parse(response.body)['contacts']['active']).to eq 1
    end
  end
end
