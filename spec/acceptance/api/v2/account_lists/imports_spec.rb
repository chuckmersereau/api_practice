require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Import' do
  let(:resource_type) { 'imports' }
  let!(:user) { create(:user_with_account) }
  let!(:fb_account) { create(:facebook_account, person_id: user.id) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let(:import) do
    create(:import, account_list: account_list, user: user,
                    source_account_id: fb_account.id)
  end
  let(:id) { import.id }
  let(:new_import) { build(:import, account_list_id: account_list.id, user_id: user.id, source_account_id: fb_account.id).attributes }
  let(:form_data) { build_data(new_import) }
  let(:expected_attribute_keys) do
    %w(account-list-id
       created-at
       import-by-group
       file
       group-tags
       groups
       override
       source
       source-account-id
       tags
       updated-at
       user-id)
  end

  before do
    stub_request(:get, "https://graph.facebook.com/#{fb_account.remote_id}/friends?access_token=#{fb_account.token}")
      .to_return(body: '{"data": [{"name": "David Hylden","id": "120581"}]}')
    stub_request(:get, "https://graph.facebook.com/120581?access_token=#{fb_account.token}")
      .to_return(body: '{"id": "120581", "first_name": "John", "last_name": "Doe", "relationship_status": "Married", "significant_other":{"id":"120582"}}')
    stub_request(:get, "https://graph.facebook.com/120582?access_token=#{fb_account.token}")
      .to_return(body: '{"id": "120582", "first_name": "Jane", "last_name": "Doe"}')
  end
  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account-lists/:account_list_id/imports/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'file',                    'File', 'Type' => 'String'
        response_field 'groups',                  'Groups', 'Type' => 'String'
        response_field 'group-tags',              'Group Tags', 'Type' => 'String'
        response_field 'import-by-group',         'Import by Group', 'Type' => 'Boolean'
        response_field 'override',                'Override', 'Type' => 'Boolean'
        response_field 'source',                  'Source', 'Type' => 'String'
        response_field 'source-account-id',       'Source Account ID', 'Type' => 'Number'
        response_field 'tags',                    'Tags', 'Type' => 'Array.new(10) { iii }'
        response_field 'user-id',                 'User ID', 'Type' => 'Number'
      end
      example_request 'get import' do
        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
    post '/api/v2/account-lists/:account_list_id/imports' do
      with_options scope: [:data, :attributes] do
        parameter 'file',                         'File'
        parameter 'groups',                       'Groups'
        parameter 'group-tags',                   'Group Tags'
        parameter 'import-by-group',              'Import by Group'
        parameter 'override',                     'Override'
        parameter 'source',                       'Source'
        parameter 'source-account-id',            'Source Account ID'
        parameter 'tags',                         'Tags'
        parameter 'user-id',                      'User ID'
      end
      example 'create prayer letters account' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end
  end
end
