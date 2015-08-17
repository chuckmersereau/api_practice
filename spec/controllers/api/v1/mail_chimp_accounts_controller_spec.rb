require 'spec_helper'

describe Api::V1::MailChimpAccountsController do
  let(:user) { create(:user_with_account) }
  let(:mail_chimp_account) { create :mail_chimp_account, account_list: user.account_lists.first }
  let(:appeal) { create(:appeal, account_list: user.account_lists.first) }

  context '#export_appeal_list' do
    it 'queues export' do
      expect(mail_chimp_account.account_list).to eq user.account_lists.first
      get 'export_appeal_list', access_token: user.access_token, appeal_id: appeal.id
      expect(response).to be_success
    end
  end
end
