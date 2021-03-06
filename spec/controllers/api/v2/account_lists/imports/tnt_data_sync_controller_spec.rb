require 'rails_helper'

describe Api::V2::AccountLists::Imports::TntDataSyncController, type: :controller do
  let(:factory_type) { :import }
  let(:resource_type) { :imports }

  let!(:user) { create(:user_with_account) }
  let!(:fb_account) { create(:facebook_account, person: user) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let(:organization_account) { create(:organization_account, person: user) }
  let(:import) do
    create(:tnt_import, account_list: account_list, user: user, source_account_id: organization_account.id)
  end
  let(:id) { import.id }

  let(:resource) { import }
  let(:parent_param) { { account_list_id: account_list_id } }

  let(:correct_attributes) do
    file_path = Rails.root.join('spec', 'fixtures', 'tnt', 'tnt_data_sync_no_org_lowercase_fields.tntmpd')
    attributes_for(:import, file: Rack::Test::UploadedFile.new(file_path))
  end

  let(:correct_relationships) do
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
          type: 'organization_accounts',
          id: organization_account.id
        }
      }
    }
  end

  let(:incorrect_attributes) { { file: nil } }

  let(:unpermitted_attributes) { nil }

  before(:each) do
    request.headers['CONTENT_TYPE'] = 'multipart/form-data'
  end

  include_examples 'create_examples'

  describe '#create' do
    it 'creates a file' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
      end.to change { resource.class.count }.by(1)
      expect(response.status).to eq(201)
      import = Import.find_by_id(JSON.parse(response.body)['data']['id'])
      expect(import.file).to be_present
      expected_file_path = "uploads/import/file/#{import.id}/tnt_data_sync_no_org_lowercase_fields.tntmpd"
      expect(import.file.path).to end_with(expected_file_path)
    end

    it 'defaults source to tnt_data_sync' do
      api_login(user)
      post :create, full_correct_attributes.merge(source: 'bogus')
      import = Import.find_by_id(JSON.parse(response.body)['data']['id'])
      expect(import.source).to eq 'tnt_data_sync'
    end

    it 'defaults user_id to current user' do
      api_login(user)
      full_correct_attributes[:data][:relationships].delete(:user)
      post :create, full_correct_attributes
      import = Import.find_by_id(JSON.parse(response.body)['data']['id'])
      expect(import.user_id).to eq user.id
    end
  end
end
