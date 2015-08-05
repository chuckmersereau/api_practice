require 'spec_helper'

describe Api::V1::MailChimpAccountsController do
  let(:user) { create(:user_with_account) }
  before { sign_in(:user, user) }

  context 'available_appeal_lists' do
    it 'returns and empty list if there is no mail chimp account' do
      get :available_appeal_lists
      expect(JSON.parse(response.body)).to eq('mail_chimp_accounts' => [])
    end
  end
end
