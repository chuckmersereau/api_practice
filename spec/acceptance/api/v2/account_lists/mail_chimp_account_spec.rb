require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Mailchimp Account Spec' do
  let(:resource_type) { 'mail-chimp-accounts' }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let(:primary_list_id) { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }
  let(:mail_chimp_account) { MailChimpAccount.new(api_key: 'fake-us4', primary_list_id: primary_list_id) }
  let(:account_list_with_mailchimp) { create(:account_list, mail_chimp_account: mail_chimp_account) }
  let(:appeal) { create(:appeal, account_list: account_list) }

  before do
    allow_any_instance_of(MailChimpAccount).to receive(:queue_export_to_primary_list)
    allow_any_instance_of(MailChimpAccount).to receive(:lists).and_return([])
    allow_any_instance_of(MailChimpAccount).to receive(:validate_key)
    mail_chimp_account.account_list = account_list
    mail_chimp_account.save
    api_login(user)
  end

  get '/api/v2/account_lists/:account_list_id/mail_chimp_account' do
    with_options scope: [:data, :attributes] do
      response_field 'api-key',                 'API Key', 'Type' => 'String'
      response_field 'valid',                   'Valid', 'Type' => 'Boolean'
      response_field 'validation-error',        'Validation Error', 'Type' => 'String'
      response_field 'active',                  'Active', 'Type' => 'Boolean'
      response_field 'validate-key',            'Validate Key', 'Type' => 'Boolean'
      response_field 'auto-log-campaigns',      'Auto Log Campaigns', 'Type' => 'Boolean'
      response_field 'primary-list-id',         'Primary List ID', 'Type' => 'Integer'
      response_field 'primary-list-name',       'Primary List Name', 'Type' => 'String'
      response_field 'lists-link',              'Lists Link', 'Type' => 'String'
      response_field 'sync-all-active-contacts', 'Sync all active contacts', 'Type' => 'Boolean'
      response_field 'lists-present', 'Lists Present', 'Type' => 'Boolean'
      response_field 'lists-available-for-newsletters', 'Lists available for newsletters', 'Type' => 'Array'
    end
    example_request 'get mailchimp account' do
      check_resource
      expect(resource_object.keys).to eq %w(api-key validation-error active validate-key auto-log-campaigns primary-list-id
                                            primary-list-name lists-link sync-all-active-contacts lists-present valid lists-available-for-newsletters)
      expect(status).to eq 200
    end
  end
  delete '/api/v2/account_lists/:account_list_id/mail_chimp_account' do
    parameter 'account-list-id',              'Account List ID', required: true
    parameter 'id',                           'ID', required: true
    example_request 'delete mailchimp account' do
      expect(status).to eq 200
    end
  end
  get '/api/v2/account_lists/:account_list_id/mail_chimp_account/sync' do
    parameter 'account-list-id', 'Account List ID', required: true
    example_request 'sync mailchimp account' do
      expect(status).to eq 200
    end
  end
end
