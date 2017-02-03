require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Import from TNT XML' do
  include_context :multipart_form_data_headers
  include ActionDispatch::TestProcess

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
      account_list_id: account_list.uuid,
      user_id: user.uuid,
      source_account_id: fb_account.uuid,
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'tnt', 'tnt_export.xml'))
    }
    build(:import).attributes.tap { |a| a.delete('uuid') }.merge(attrs)
  end

  let(:form_data) { build_data(new_import) }

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/account_lists/:account_list_id/imports/tnt' do
      with_options scope: [:data, :attributes] do
        parameter 'file',              'File',              'Type' => 'String'
        parameter 'groups',            'Groups',            'Type' => 'String'
        parameter 'group_tags',        'Group Tags',        'Type' => 'String'
        parameter 'import_by_group',   'Import by Group',   'Type' => 'String'
        parameter 'override',          'Override',          'Type' => 'Boolean'
        parameter 'source',            'Source',            'Type' => 'String'
        parameter 'source_account_id', 'Source Account ID', 'Type' => 'String'
        parameter 'tags',              'Tags',              'Type' => 'String'
        parameter 'user_id',           'User ID',           'Type' => 'String'
      end

      example 'Import [CREATE]', document: :account_lists do
        explanation 'Creates a new Import associated with the Account List, this endpoint supports Content-Type multipart/form-data to handle the file upload'
        do_request data: form_data
        expect(response_status).to eq 201
        expect(response_headers['Content-Type']).to eq 'application/vnd.api+json; charset=utf-8'
        expect(resource_data['id']).to be_present
        expect(resource_data['attributes']['file']['file']['url']).to be_present
      end
    end
  end
end