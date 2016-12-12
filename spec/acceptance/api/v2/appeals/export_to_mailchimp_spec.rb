require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Mailchimp' do
  include_context :json_headers

  let(:resource_type) { 'mail-chimp-account' }
  let!(:user)         { create(:user_with_account) }

  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:appeal)   { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.id }

  let(:primary_list_id)    { '1e72b58b72' }
  let(:mail_chimp_account) { MailChimpAccount.new(api_key: 'fake-us4', primary_list_id: primary_list_id) }

  let(:form_data) { build_data(appeal_list_id: primary_list_id) }

  before do
    allow_any_instance_of(MailChimpAccount).to receive(:queue_export_to_primary_list)
    allow_any_instance_of(MailChimpAccount).to receive(:lists).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:validate_key)
    mail_chimp_account.account_list = account_list
    mail_chimp_account.save
    api_login(user)
  end

  context 'authorized user' do
    get '/api/v2/appeals/:appeal_id/export_to_mailchimp' do
      parameter 'account_list_id', 'Account List ID', required: true, scope: :filters
      parameter 'appeal_list_id',  'Appeal List ID', required: true

      example 'Export to Mailchimp [GET]', document: :appeals do
        explanation 'Export the Appeal with the given ID to the MailChimp server'
        do_request data: form_data

        expect(response_status).to eq 200
      end
    end
  end
end
