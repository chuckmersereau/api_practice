require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Imports > from TNT XML' do
  include_context :multipart_form_data_headers
  include ActionDispatch::TestProcess
  documentation_scope = :account_lists_api_imports

  before { stub_smarty_streets }

  let(:resource_type) { 'imports' }
  let!(:user)         { create(:user_with_account) }

  let!(:fb_account)     { create(:facebook_account, person_id: user.id) }
  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:import) do
    create(:import, account_list: account_list, user: user,
                    source_account_id: fb_account.uuid)
  end
  let(:id) { import.uuid }

  let(:new_import) do
    attrs = {
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'tnt', 'tnt_export.xml'))
    }

    attributes_for(:import)
      .reject { |attr| attr.to_s.end_with?('_id') }
      .tap { |attributes| attributes.delete('uuid') }.merge(attrs)
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.uuid
        }
      },
      user: {
        data: {
          type: 'users',
          id: user.uuid
        }
      },
      source_account: {
        data: {
          type: 'facebook_accounts',
          id: fb_account.uuid
        }
      }
    }
  end

  let(:resource_attributes) do
    %w(
      account_list_id
      created_at
      file
      file_headers
      group_tags
      groups
      import_by_group
      in_preview
      override
      source
      tags
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      user
    )
  end

  let(:form_data) { build_data(new_import, relationships: relationships) }

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/account_lists/:account_list_id/imports/tnt' do
      with_options scope: [:data, :attributes] do
        parameter 'file',              'File',                                                   'Type' => 'String'
        parameter 'file_headers',      'File Headers',                                           'Type' => 'String'
        parameter 'groups',            'Groups',                                                 'Type' => 'String'
        parameter 'group_tags',        'Group Tags',                                             'Type' => 'String'
        parameter 'import_by_group',   'Import by Group',                                        'Type' => 'String'
        parameter 'in_preview',        "The Import will not be performed while it's in preview", 'Type' => 'Boolean'
        parameter 'override',          'Override',                                               'Type' => 'Boolean'
        parameter 'source_account_id', 'Source Account ID',                                      'Type' => 'String'
        parameter 'tags',              'Tags',                                                   'Type' => 'String'
        parameter 'user_id',           'User ID',                                                'Type' => 'String'
      end

      with_options scope: [:data, :attributes] do
        response_field 'account_list_id',  'Account List ID',                                                           'Type' => 'Number'
        response_field 'created_at',       'Created At',                                                                'Type' => 'String'
        response_field 'file',             'File',                                                                      'Type' => 'Object'
        response_field 'file_headers',     'File Headers',                                                              'Type' => 'Array[String]'
        response_field 'group_tags',       'Group Tags',                                                                'Type' => 'String'
        response_field 'groups',           'Groups',                                                                    'Type' => 'Array[String]'
        response_field 'import_by_group',  'Import by Group',                                                           'Type' => 'String'
        response_field 'in_preview',       "The Import will not be performed while it's in preview; Defaults to false", 'Type' => 'Boolean'
        response_field 'override',         'Override',                                                                  'Type' => 'String'
        response_field 'source',           'Source; Defaults to "tnt"',                                                 'Type' => 'String'
        response_field 'tags',             'Tags',                                                                      'Type' => 'String'
        response_field 'updated_at',       'Updated At',                                                                'Type' => 'String'
        response_field 'updated_in_db_at', 'Updated In Db At',                                                          'Type' => 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'user', 'User that the Import belongs to', 'Type' => 'Object'
      end

      example 'Import [CREATE]', document: documentation_scope do
        explanation 'Creates a new Import associated with the Account List, this endpoint supports Content-Type multipart/form-data to handle the file upload'
        do_request data: form_data
        check_resource(['relationships'])
        expect(response_status).to eq(201), invalid_status_detail
        expect(response_headers['Content-Type']).to eq 'application/vnd.api+json; charset=utf-8'
        expect(resource_data['id']).to be_present
        expect(resource_data['attributes']['file']['file']['url']).to be_present
        expect(resource_data['attributes']['source']).to eq 'tnt'
        expect(resource_data['attributes']['in_preview']).to eq false
      end
    end
  end
end
