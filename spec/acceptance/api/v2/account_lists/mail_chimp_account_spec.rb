require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Mailchimp Account Spec' do
  include_context :json_headers

  let(:resource_type) { 'mail_chimp_accounts' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let(:primary_list_id)   { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }

  let(:mail_chimp_account)          { MailChimpAccount.new(api_key: 'fake-us4', primary_list_id: primary_list_id) }
  let(:account_list_with_mailchimp) { create(:account_list, mail_chimp_account: mail_chimp_account) }
  let(:appeal)                      { create(:appeal, account_list: account_list) }

  let(:expected_attribute_keys) do
    %w(
      active
      api_key
      auto_log_campaigns
      created_at
      lists_available_for_newsletters
      lists_link
      lists_present
      primary_list_name
      sync_all_active_contacts
      updated_at
      valid
      validate_key
      validation_error
    )
  end

  let(:resource_associations) do
    %w(
      primary_list
    )
  end

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
      response_field 'active',                          'Active',                          'Type' => 'Boolean'
      response_field 'api_key',                         'API Key',                         'Type' => 'String'
      response_field 'auto_log_campaigns',              'Auto Log Campaigns',              'Type' => 'Boolean'
      response_field 'lists_available_for_newsletters', 'Lists available for newsletters', 'Type' => 'Array[Object]'
      response_field 'lists_link',                      'Lists Link',                      'Type' => 'String'
      response_field 'lists_present',                   'Lists Present',                   'Type' => 'Boolean'
      response_field 'primary_list_id',                 'Primary List ID',                 'Type' => 'Number'
      response_field 'primary_list_name',               'Primary List Name',               'Type' => 'String'
      response_field 'sync_all_active_contacts',        'Sync all active contacts',        'Type' => 'Boolean'
      response_field 'valid',                           'Valid',                           'Type' => 'Boolean'
      response_field 'validation_error',                'Validation Error',                'Type' => 'String'
      response_field 'validate_key',                    'Validate Key',                    'Type' => 'Boolean'
    end

    example 'Mailchimp Account [GET]', document: :account_lists do
      do_request
      check_resource(['relationships'])
      expect(resource_object.keys).to match_array expected_attribute_keys
      expect(response_status).to eq 200
    end
  end

  delete '/api/v2/account_lists/:account_list_id/mail_chimp_account' do
    parameter 'account_list_id', 'Account List ID', required: true
    parameter 'id',              'ID', required: true

    example 'Mailchimp Account [DELETE]', document: :account_lists do
      do_request
      expect(response_status).to eq 204
    end
  end

  get '/api/v2/account_lists/:account_list_id/mail_chimp_account/sync' do
    parameter 'account_list_id', 'Account List ID', required: true

    example 'Mailchimp Account [SYNC]', document: :account_lists do
      do_request
      expect(response_status).to eq 200
    end
  end
end
