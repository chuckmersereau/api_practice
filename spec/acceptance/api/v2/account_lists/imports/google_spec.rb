require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Imports > from Google' do
  include_context :json_headers
  documentation_scope = :account_lists_api_imports

  before do
    stub_smarty_streets
    stub_request(:get, 'https://www.google.com/m8/feeds/contacts/default/full'\
                       '?alt=json&'\
                       'group=http://www.google.com/m8/feeds/groups/test%2540gmail.com/base/d&'\
                       'max-results=100000&v=3')
  end

  let(:resource_type) { 'imports' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:google_account) { create(:google_account, person_id: user.id) }

  let(:new_import) do
    {
      'in_preview' => false,
      'tag_list' => 'test,poster',
      'groups' => [
        'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/d',
        'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/f'
      ],
      'import_by_group' => 'true',
      'override' => 'true',
      'source' => 'google',
      'group_tags' => {
        'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/6' => 'my-contacts',
        'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/d' => 'friends'
      }
    }
  end

  let(:relationships) do
    {
      source_account: {
        data: {
          type: 'google_accounts',
          id: google_account.uuid
        }
      }
    }
  end

  let(:resource_attributes) do
    %w(
      file_constants
      file_constants_mappings
      file_headers
      file_headers_mappings
      file_url
      account_list_id
      created_at
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

    post '/api/v2/account_lists/:account_list_id/imports/google' do
      with_options scope: [:data, :attributes] do
        parameter 'groups',            'Array of Groups (items are group_id)',                           type: 'String'
        parameter 'group_tags',        'Group Tags (key: group_id, value: Comma delimited list of tags', type: 'Object'
        parameter 'import_by_group',   'Import by Group',                                                type: 'String'
        parameter 'in_preview',        "The Import will not be performed while it's in preview",         type: 'Boolean'
        parameter 'override',          'Override',                                                       type: 'Boolean'
        parameter 'source_account_id', 'Source Account ID',                                              type: 'String'
        parameter 'tag_list',          'Comma delimited list of Tags',                                   type: 'String'
      end

      with_options scope: [:data, :attributes] do
        response_field 'account_list_id',         'Account List ID',                                                           type: 'Number'
        response_field 'created_at',              'Created At',                                                                type: 'String'
        response_field 'file_url',                'Not applicable to Google imports.',                                         type: 'String'
        response_field 'file_headers_mappings',   'Not applicable to Google imports.',                                         type: 'Object'
        response_field 'file_headers',            'Not applicable to Google imports.',                                         type: 'Object'
        response_field 'file_constants',          'Not applicable to Google imports.',                                         type: 'Object'
        response_field 'file_constants_mappings', 'Not applicable to Google imports.',                                         type: 'Object'
        response_field 'group_tags',              'Group Tags',                                                                type: 'Object'
        response_field 'groups',                  'Groups',                                                                    type: 'Array[String]'
        response_field 'import_by_group',         'Import by Group',                                                           type: 'String'
        response_field 'in_preview',              "The Import will not be performed while it's in preview; Defaults to false", type: 'Boolean'
        response_field 'override',                'Override',                                                                  type: 'Boolean'
        response_field 'source',                  'Source; Defaults to "google"',                                              type: 'String'
        response_field 'tag_list',                'Comma delimited list of Tags',                                              type: 'String'
        response_field 'updated_at',              'Updated At',                                                                type: 'String'
        response_field 'updated_in_db_at',        'Updated In Db At',                                                          type: 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'user', 'User that the Import belongs to', type: 'Object'
      end

      example 'Google Import [CREATE]', document: documentation_scope do
        explanation 'Creates a new Google Import associated with the Account List. Unless otherwise specified, the Import will be created with ' \
                    '"in_preview" set to false, which will cause the import to begin after being created (the import runs asynchronously as a background job).'
        do_request data: form_data
        expect(response_status).to eq(201), invalid_status_detail
        check_resource(['relationships'])
        expect(response_headers['Content-Type']).to eq 'application/vnd.api+json; charset=utf-8'
        expect(resource_data['id']).to be_present
        expect(resource_data['attributes']['source']).to eq 'google'
        expect(resource_data['attributes']['in_preview']).to eq false
        expect(resource_data['attributes']['tag_list']).to eq 'test,poster'
        expect(resource_data['attributes']['import_by_group']).to eq true
        expect(resource_data['attributes']['groups']).to eq [
          'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/d',
          'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/f'
        ]
        expect(resource_data['attributes']['group_tags']).to eq(
          'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/6' => 'my-contacts',
          'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/d' => 'friends'
        )
      end
    end
  end
end
