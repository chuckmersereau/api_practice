require 'rails_helper'

describe Api::V2::AccountLists::Imports::CsvController, type: :controller do
  let(:factory_type) { :import }
  let(:resource_type) { :imports }

  let!(:user) { create(:user_with_account) }
  let!(:fb_account) { create(:facebook_account, person: user) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let(:import) { create(:import, account_list: account_list, user: user, source_account_id: fb_account.id) }
  let(:id) { import.uuid }

  let(:resource) { import }
  let(:parent_param) { { account_list_id: account_list_id } }

  let(:correct_attributes) do
    attributes_for(:import, file: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'sample_csv_to_import.csv')))
  end

  let(:correct_relationships) do
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

  let(:incorrect_attributes) { { source: nil } }

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
      import = Import.find_by_uuid(JSON.parse(response.body)['data']['id'])
      expect(import.file).to be_present
      expect(import.file.path).to end_with("uploads/import/file/#{import.id}/sample_csv_to_import.csv")
    end

    it 'defaults source to csv' do
      api_login(user)
      post :create, full_correct_attributes.merge(source: 'bogus')
      import = Import.find_by_uuid(JSON.parse(response.body)['data']['id'])
      expect(import.source).to eq 'csv'
    end

    it 'defaults in_preview to true' do
      api_login(user)
      post :create, full_correct_attributes.merge(in_preview: false)
      import = Import.find_by_uuid(JSON.parse(response.body)['data']['id'])
      expect(import.in_preview?).to eq true
    end
  end
end
