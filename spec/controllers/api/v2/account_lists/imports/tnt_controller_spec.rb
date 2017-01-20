require 'spec_helper'

describe Api::V2::AccountLists::Imports::TntController, type: :controller do
  let(:factory_type) { :import }
  let!(:user) { create(:user_with_account) }
  let!(:fb_account) { create(:facebook_account, person: user) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let(:import) { create(:import, account_list: account_list, user: user, source_account_id: fb_account.id) }
  let(:id) { import.uuid }

  let(:resource) { import }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) do
    attributes_for(:import,
                   account_list_id: account_list.uuid,
                   user_id: user.uuid,
                   source_account_id: fb_account,
                   file: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'tnt', 'tnt_export.xml')))
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
      expect(import.file.path).to end_with("uploads/import/file/#{import.id}/tnt_export.xml")
    end
  end
end
