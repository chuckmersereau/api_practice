require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Export to MailChimp' do
  include_context :json_headers
  documentation_scope = :contacts_api_exports

  let(:resource_type) { 'mail-chimp-account' }
  let!(:user)         { create(:user_with_account) }

  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:appeal)   { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.uuid }

  let(:primary_list_id) { '1e72b58b72' }
  let(:second_list_id) { '1e72b58b44' }
  let(:mail_chimp_account) { MailChimpAccount.new(api_key: 'fake-us4', primary_list_id: primary_list_id) }

  before do
    allow(MailChimp::ExportContactsWorker).to receive(:perform_async)
    allow_any_instance_of(MailChimpAccount).to receive(:lists).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:validate_key)
    mail_chimp_account.account_list = account_list
    mail_chimp_account.save
    api_login(user)
  end

  context 'authorized user' do
    post '/api/v2/contacts/export_to_mail_chimp' do
      parameter 'account_list_id', 'Account List ID', scope: :filter
      parameter 'contact_ids', 'Account List ID', scope: :filter
      parameter 'mail_chimp_list_id', 'Mail Chimp List ID', required: true

      example 'Export to Mail Chimp [POST]', document: documentation_scope do
        explanation 'Export Contacts with the given ID to the Mail Chimp server'
        do_request mail_chimp_list_id: second_list_id

        expect(response_status).to eq 200
      end
    end
  end
end
