require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Imports' do
  include_context :json_headers
  documentation_scope = :account_lists_api_imports

  let(:resource_type) { 'imports' }
  let!(:user)         { create(:user_with_account) }

  let!(:fb_account)     { create(:facebook_account, person_id: user.id) }
  let!(:account_list)   { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let(:import) do
    create(:import, account_list: account_list, user: user,
                    source_account_id: fb_account.id)
  end
  let(:id) { import.id }

  let(:new_import) do
    attrs = {
      account_list_id: account_list.id,
      user_id: user.id,
      source_account_id: fb_account.id
    }

    attributes_for(:import).merge(attrs)
  end

  let(:form_data) { build_data(new_import) }

  let(:resource_attributes) do
    %w(
      account_list_id
      created_at
      file_constants
      file_constants_mappings
      file_headers
      file_headers_mappings
      file_url
      group_tags
      groups
      import_by_group
      in_preview
      override
      source
      tag_list
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      sample_contacts
      user
    )
  end

  before do
    stub_request(:get, "https://graph.facebook.com/#{fb_account.remote_id}/friends?access_token=#{fb_account.token}")
      .to_return(body: '{"data": [{"name": "David Hylden","id": "120581"}]}')
    spouse_expected_response = '{"id": "120581", "first_name": "John", "last_name": "Doe", '\
                               '"relationship_status": "Married", "significant_other":{"id":"120582"}}'
    stub_request(:get, "https://graph.facebook.com/120581?access_token=#{fb_account.token}")
      .to_return(body: spouse_expected_response)
    stub_request(:get, "https://graph.facebook.com/120582?access_token=#{fb_account.token}")
      .to_return(body: '{"id": "120582", "first_name": "Jane", "last_name": "Doe"}')
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/imports/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',              'Created At',                     type: 'String'
        response_field 'file_url',                'A URL to download the file',     type: 'String'
        response_field 'file_headers_mappings',   'Only applicable to CSV Imports', type: 'Object'
        response_field 'file_headers',            'Only applicable to CSV Imports', type: 'Object'
        response_field 'file_constants',          'Only applicable to CSV Imports', type: 'Object'
        response_field 'file_constants_mappings', 'Only applicable to CSV Imports', type: 'Object'
        response_field 'groups',                  'Groups',                         type: 'String'
        response_field 'group_tags',              'Group Tags',                     type: 'String'
        response_field 'import_by_group',         'Import by Group',                type: 'Boolean'
        response_field 'override',                'Override',                       type: 'Boolean'
        response_field 'source',                  'Source',                         type: 'String'
        response_field 'source_account_id',       'Source Account ID',              type: 'Number'
        response_field 'tag_list',                'Comma delimited list of Tags',   type: 'String'
        response_field 'user_id',                 'User ID',                        type: 'Number'
        response_field 'updated_at',              'Updated At',                     type: 'String'
        response_field 'updated_in_db_at',        'Updated In Db At',               type: 'String'
      end

      example 'Import [GET]', document: documentation_scope do
        explanation 'Creates a new Import associated with the Account List. This endpoint accepts ' \
                    'a file to be uploaded using Content-Type "multipart/form-data", this makes ' \
                    'the endpoint unique in that it does not only accept JSON content. Unless ' \
                    'otherwise specified, the Import will be created with "in_preview" set to ' \
                    'false, which will cause the import to begin after being created ' \
                    '(the import runs asynchronously as a background job).'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
