require 'spec_helper'

describe Api::V2::Contacts::ExportToMailChimpController, type: :controller do
  let(:factory_type) { :mail_chimp_account }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:account_list_id) { account_list.uuid }
  let(:appeal_id) { appeal.uuid }
  let(:primary_list_id) { '1e72b58b72' }
  let(:mail_chimp_account) { build(:mail_chimp_account, primary_list_id: primary_list_id) }
  let!(:first_contact) { create(:contact, account_list: account_list, appeals: [appeal]) }
  let!(:second_contact) { create(:contact, account_list: account_list, appeals: [appeal]) }

  before do
    allow_any_instance_of(MailChimpAccount).to receive(:queue_export_to_primary_list)
    allow_any_instance_of(MailChimpAccount).to receive(:lists).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:validate_key)
    mail_chimp_account.account_list = account_list
    mail_chimp_account.save
  end

  context '#export' do
    it 'returns 401 when user is not signed in' do
      post :create, mailchimp_list_id: primary_list_id
      expect(response.status).to eq(401)
    end

    it 'returns a 400 with error message when mailchimp_list_id is not provided' do
      api_login(user)
      post :create
      expect(response.status).to eq(400)
      expect(JSON.parse(response.body)['errors'].first['detail']).to eq('mail_chimp_list_id must be provided')
    end

    it 'queues export when user is logged in and provides mailchimp_list_id' do
      api_login(user)
      expect_any_instance_of(MailChimpAccount).to receive(:queue_export_appeal_contacts).with(
        [first_contact.id, second_contact.id], primary_list_id, appeal.id
      )
      post :create, mail_chimp_list_id: primary_list_id
      expect(response).to be_success
    end

    it 'queues export only the contacts in contact_id filter that belong to the user' do
      api_login(user)
      expect_any_instance_of(MailChimpAccount).to receive(:queue_export_appeal_contacts).with(
        [first_contact.id], primary_list_id, appeal.id
      )
      post :create, filter: { contact_ids: [first_contact.uuid, create(:contact).uuid] }, mail_chimp_list_id: primary_list_id
      expect(response).to be_success
    end
  end
end
