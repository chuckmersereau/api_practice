require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Mailchimp Accounts' do
  include_context :json_headers
  documentation_scope = :account_lists_api_mailchimp_accounts

  let(:resource_type) { 'mail_chimp_accounts' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let(:primary_list_id)   { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }

  let!(:mail_chimp_account)  { create(:mail_chimp_account, account_list: account_list, api_key: 'fake-us4', primary_list_id: primary_list_id) }
  let(:appeal)               { create(:appeal, account_list: account_list) }
  let(:form_data)            { build_data(api_key: 'fake-us4', primary_list_id: primary_list_id) }

  let(:resource_attributes) do
    %w(
      active
      api_key
      auto_log_campaigns
      created_at
      lists_available_for_newsletters
      lists_link
      lists_present
      primary_list_id
      primary_list_name
      sync_all_active_contacts
      valid
      validate_key
      validation_error
      updated_at
      updated_in_db_at
    )
  end

  before do
    allow_any_instance_of(MailChimp::PrimaryListSyncWorker).to receive(:perform)
    allow_any_instance_of(MailChimp::GibbonWrapper).to receive(:lists).and_return([])
    allow_any_instance_of(MailChimp::GibbonWrapper).to receive(:validate_key)
    api_login(user)
  end

  get '/api/v2/account_lists/:account_list_id/mail_chimp_account' do
    with_options scope: [:data, :attributes] do
      response_field 'active',                          'Active',                          type: 'Boolean'
      response_field 'api_key',                         'API Key',                         type: 'String'
      response_field 'auto_log_campaigns',              'Auto Log Campaigns',              type: 'Boolean'
      response_field 'created_at',                      'Created At',                      type: 'String'
      response_field 'lists_available_for_newsletters', 'Lists available for newsletters', type: 'Array[Object]'
      response_field 'lists_link',                      'Lists Link',                      type: 'String'
      response_field 'lists_present',                   'Lists Present',                   type: 'Boolean'
      response_field 'primary_list_id',                 'Primary List ID',                 type: 'Number'
      response_field 'primary_list_name',               'Primary List Name',               type: 'String'
      response_field 'sync_all_active_contacts',        'Sync all active contacts',        type: 'Boolean'
      response_field 'updated_at',                      'Updated At',                      type: 'String'
      response_field 'updated_in_db_at',                'Updated In Db At',                type: 'String'
      response_field 'valid',                           'Valid',                           type: 'Boolean'
      response_field 'validation_error',                'Validation Error',                type: 'String'
      response_field 'validate_key',                    'Validate Key',                    type: 'Boolean'
    end

    example 'Mailchimp Account [GET]', document: documentation_scope do
      explanation 'The MailChimp Account associated with the Account List'
      do_request
      check_resource
      expect(response_status).to eq 200
    end
  end

  delete '/api/v2/account_lists/:account_list_id/mail_chimp_account' do
    parameter 'account_list_id', 'Account List ID', required: true
    parameter 'id',              'ID', required: true

    example 'Mailchimp Account [DELETE]', document: documentation_scope do
      explanation 'Deletes the MailChimp Account associated with the Account List'
      do_request
      expect(response_status).to eq 204
    end
  end

  post '/api/v2/account_lists/:account_list_id/mail_chimp_account' do
    parameter 'account_list_id', 'Account List ID', required: true

    with_options scope: [:data, :attributes] do
      parameter 'active',                          'Active Account or Not',           type: 'Boolean'
      parameter 'api_key',                         'API Key',                         type: 'String', required: true
      parameter 'auto_log_campaigns',              'Auto Log Campaigns or Not',       type: 'Boolean'
      parameter 'lists_available_for_newsletters', 'Lists available for newsletters', type: 'Array[Object]'
      parameter 'lists_link',                      'Lists Link',                      type: 'String'
      parameter 'lists_present',                   'Lists Present or Not',            type: 'Boolean'
      parameter 'primary_list_id',                 'Primary List ID',                 type: 'String', required: true
      parameter 'primary_list_name',               'Primary List Name',               type: 'String'
      parameter 'sync_all_active_contacts',        'Sync all active contacts',        type: 'Boolean'
      parameter 'valid',                           'Valid',                           type: 'Boolean'
      parameter 'validation_error',                'Validation Error',                type: 'String'
      parameter 'validate_key',                    'Validate Key or Not',             type: 'Boolean'
    end

    example 'Mailchimp Account [POST]', document: documentation_scope do
      explanation 'Add the MailChimp Account associated with the Account List'
      do_request data: form_data
      check_resource
      expect(response_status).to eq 201
    end
  end

  get '/api/v2/account_lists/:account_list_id/mail_chimp_account/sync' do
    parameter 'account_list_id', 'Account List ID', required: true

    example 'Mailchimp Account [SYNC]', document: documentation_scope do
      explanation "Synchronizes the Account List's contacts to the MailChimp server"
      do_request
      expect(response_status).to eq 200
    end
  end
end
