require 'rails_helper'

describe Api::V2::AccountLists::MailChimpAccountsController, type: :controller do
  let(:factory_type) { :mail_chimp_account }
  let!(:user)        { create(:user_with_account) }
  let(:given_resource_type) { 'mail_chimp_accounts' }

  let!(:account_list)     { user.account_lists.first }
  let(:account_list_id)   { account_list.uuid }
  let(:primary_list_id)   { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }

  let(:mail_chimp_account) { MailChimpAccount.new(api_key: 'fake-us4', primary_list_id: primary_list_id) }

  let!(:account_list_with_mailchimp) { create(:account_list, mail_chimp_account: mail_chimp_account) }

  let(:appeal) { create(:appeal, account_list: account_list) }

  before do
    allow_any_instance_of(MailChimpAccount).to receive(:lists).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:lists_available_for_newsletters_formatted).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:lists_link).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:primary_list_name)
    allow_any_instance_of(MailChimpAccount).to receive(:validate_key)

    mail_chimp_account.account_list = account_list
    mail_chimp_account.save
  end

  let!(:resource) { mail_chimp_account }
  let(:parent_param) { { account_list_id: account_list_id } }

  let(:correct_attributes) do
    attributes_for(:mail_chimp_account, primary_list_id: primary_list_id)
  end

  let(:incorrect_attributes) do
    attributes_for(:mail_chimp_account, api_key: nil)
      .reject { |attr| attr.to_s.end_with?('_id') }
  end

  let(:unpermitted_attributes) { nil }

  let(:given_reference_key) { :primary_list_id }

  include_examples 'show_examples'

  include_examples 'destroy_examples'

  describe '#create' do
    before do
      account_list.mail_chimp_account.destroy
    end

    include_examples 'create_examples'

    it 'syncs the mailchimp account after creating' do
      api_login(user)
      expect(MailChimp::PrimaryListSyncWorker).to receive(:perform_async)

      get :create, full_correct_attributes
    end

    context 'without primary_list_id' do
      let(:correct_attributes) do
        attributes_for(:mail_chimp_account, primary_list_id: nil)
      end

      it "doesn't sync the mailchimp account" do
        api_login(user)
        expect(MailChimp::PrimaryListSyncWorker).to_not receive(:perform_async)

        get :create, full_correct_attributes
      end
    end
  end

  describe '#sync' do
    before do
      api_login(user)
    end

    it 'syncs a mailchimp account' do
      expect(MailChimp::PrimaryListSyncWorker).to receive(:perform_async).with(mail_chimp_account.id)

      get :sync, account_list_id: account_list_id
      expect(response.status).to eq 200
    end
  end
end
