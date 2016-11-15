require 'spec_helper'

describe Api::V2::AccountLists::MailChimpAccountsController, type: :controller do
  let(:resource_type) { 'mail-chimp-accounts' }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let(:primary_list_id) { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }
  let(:mail_chimp_account) { MailChimpAccount.new(api_key: 'fake-us4', primary_list_id: primary_list_id) }
  let!(:account_list_with_mailchimp) { create(:account_list, mail_chimp_account: mail_chimp_account) }
  let(:appeal) { create(:appeal, account_list: account_list) }

  before do
    allow_any_instance_of(MailChimpAccount).to receive(:queue_export_to_primary_list)
    allow_any_instance_of(MailChimpAccount).to receive(:lists).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:validate_key)
    mail_chimp_account.account_list = account_list
    mail_chimp_account.save
  end

  let!(:resource) { mail_chimp_account }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { build(:mail_chimp_account, primary_list_id: primary_list_id).attributes }
  let(:incorrect_attributes) { build(:mail_chimp_account, api_key: nil).attributes }
  let(:unpermitted_attributes) { nil }

  include_examples 'show_examples'

  include_examples 'destroy_examples'

  describe '#create' do
    before do
      account_list.mail_chimp_account.destroy
    end

    include_examples 'create_examples'
  end

  describe '#sync' do
    before do
      api_login(user)
    end

    it 'syncs a mailchimp account' do
      get :sync, account_list_id: account_list_id
      expect(response.status).to eq 200
    end
  end
end
