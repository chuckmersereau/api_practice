require 'spec_helper'

describe Api::V2::BaseController do
  describe 'api' do
    let(:user) { create(:user_with_account) }

    before do
      get '/oauth/authorize?response_type=token&access_token=' + user.access_token
    end

    it 'responds 200' do
      expect(response.code).to eq('200')
    end
  end
end
