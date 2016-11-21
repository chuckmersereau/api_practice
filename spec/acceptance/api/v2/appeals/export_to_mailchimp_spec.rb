require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Mailchimp' do
  let(:resource_type) { 'mail-chimp-account' }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:account_list_id) { account_list.id }
  let(:appeal_id) { appeal.id }
  let(:primary_list_id) { '1e72b58b72' }
  let(:mail_chimp_account) { MailChimpAccount.new(api_key: 'fake-us4', primary_list_id: primary_list_id) }
  let(:form_data) { build_data(appeal_list_id: primary_list_id) }

  before do
    stub_request(:get, 'https://apikey:fake-us4@us4.api.mailchimp.com/3.0/lists/1/members?count=100&offset=0')
      .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Faraday v0.9.2' })
      .to_return(status: 200, body: '', headers: {})
    allow_any_instance_of(MailChimpAccount).to receive(:queue_export_to_primary_list)
    allow_any_instance_of(MailChimpAccount).to receive(:lists).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:validate_key)
    mail_chimp_account.account_list = account_list
    mail_chimp_account.save
    api_login(user)
  end

  context 'authorized user' do
    get '/api/v2//appeals/:appeal_id/export-to-mailchimp' do
      parameter 'account_list_id', 'Account List ID', required: true, scope: :filters
      parameter 'appeal_list_id', 'Appeal List ID', required: true
      example 'list designation accounts of account list' do
        do_request data: form_data
        expect(status).to eq 200
      end
    end
  end
end
