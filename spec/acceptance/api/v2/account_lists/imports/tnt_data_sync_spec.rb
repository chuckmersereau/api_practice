require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Imports > from TNT Data Sync' do
  include_context :multipart_form_data_headers
  include ActionDispatch::TestProcess
  documentation_scope = :account_lists_api_imports

  before { stub_smarty_streets }

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
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'tnt', 'tnt_data_sync_no_org_lowercase_fields.tntmpd'))
    }

    attributes_for(:import)
      .reject { |attr| attr.to_s.end_with?('_id') }
      .tap { |attributes| attributes.delete('id') }.merge(attrs)
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.id
        }
      },
      user: {
        data: {
          type: 'users',
          id: user.id
        }
      },
      source_account: {
        data: {
          type: 'facebook_accounts',
          id: fb_account.id
        }
      }
    }
  end

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

  let(:form_data) { build_data(new_import, relationships: relationships) }

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/account_lists/:account_list_id/imports/tnt_data_sync' do
      with_options scope: [:data, :attributes] do
        parameter 'file',              'The file uploaded as form-data',                         type: 'String'
        parameter 'groups',            'Groups',                                                 type: 'String'
        parameter 'group_tags',        'Group Tags',                                             type: 'String'
        parameter 'import_by_group',   'Import by Group',                                        type: 'String'
        parameter 'in_preview',        "The Import will not be performed while it's in preview", type: 'Boolean'
        parameter 'override',          'Override',                                               type: 'Boolean'
        parameter 'source_account_id', 'Source Account ID',                                      type: 'String'
        parameter 'tag_list',          'Comma delimited list of Tags',                           type: 'String'
        parameter 'user_id',           'User ID',                                                type: 'String'
      end

      with_options scope: [:data, :attributes] do
        response_field 'account_list_id',         'Account List ID',                                                           type: 'Number'
        response_field 'created_at',              'Created At',                                                                type: 'String'
        response_field 'file_url',                'A URL to download the file',                                                type: 'String'
        response_field 'file_headers_mappings',   'Not applicable to TNT XML imports.',                                        type: 'Object'
        response_field 'file_headers',            'Not applicable to TNT XML imports.',                                        type: 'Object'
        response_field 'file_constants',          'Not applicable to TNT XML imports.',                                        type: 'Object'
        response_field 'file_constants_mappings', 'Not applicable to TNT XML imports.',                                        type: 'Object'
        response_field 'group_tags',              'Group Tags',                                                                type: 'String'
        response_field 'groups',                  'Groups',                                                                    type: 'Array[String]'
        response_field 'import_by_group',         'Import by Group',                                                           type: 'String'
        response_field 'in_preview',              "The Import will not be performed while it's in preview; Defaults to false", type: 'Boolean'
        response_field 'override',                'Override',                                                                  type: 'Boolean'
        response_field 'source',                  'Source; Defaults to "tnt"',                                                 type: 'String'
        response_field 'tag_list',                'Comma delimited list of Tags',                                              type: 'String'
        response_field 'updated_at',              'Updated At',                                                                type: 'String'
        response_field 'updated_in_db_at',        'Updated In Db At',                                                          type: 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'user', 'User that the Import belongs to', type: 'Object'
      end

      example 'TNT Data Sync Import [CREATE]', document: documentation_scope do
        explanation 'Creates a new TNT Data Sync Import associated with the Account List. This endpoint expects a .tntmpd file to be uploaded using Content-Type ' \
                    '"multipart/form-data", this makes the endpoint unique in that it does not expect JSON content. Unless otherwise specified, the Import will be created with ' \
                    '"in_preview" set to false, which will cause the import to begin after being created (the import runs asynchronously as a background job).'
        do_request data: form_data
        expect(response_status).to eq(201), invalid_status_detail
        check_resource(['relationships'])
        expect(response_headers['Content-Type']).to eq 'application/vnd.api+json; charset=utf-8'
        expect(resource_data['id']).to be_present
        expect(resource_data['attributes']['file_url']).to be_present
        expect(resource_data['attributes']['source']).to eq 'tnt_data_sync'
        expect(resource_data['attributes']['in_preview']).to eq false
      end
    end
  end
end
