require 'rails_helper'

describe Api::V2::AccountLists::Imports::CsvController, type: :controller do
  let(:factory_type) { :import }
  let(:resource_type) { :imports }

  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:account_list_id) { account_list.uuid }
  let!(:id) { import.uuid }
  let!(:parent_param) { { account_list_id: account_list_id } }
  let!(:imports) do
    create_list(:csv_import, 2, account_list: account_list, user: user, in_preview: true,
                                file_headers_mappings: file_headers_mappings, file_constants_mappings: file_constants_mappings)
  end
  let!(:import) { imports.first }
  let!(:resource) { import }

  let(:file_headers_mappings) do
    {
      'city' => 'city',
      'commitment_amount' => 'amount',
      'commitment_frequency' => 'frequency',
      'contact_name' => 'fname',
      'country' => 'country',
      'email_1' => 'email-address',
      'envelope_greeting' => 'envelope-greeting',
      'first_name' => 'fname',
      'greeting' => 'greeting',
      'last_name' => 'lname',
      'newsletter' => 'newsletter',
      'notes' => 'extra-notes',
      'phone_1' => 'phone',
      'spouse_email' => 'Spouse-email-address',
      'spouse_first_name' => 'Spouse-fname',
      'spouse_last_name' => 'Spouse-lname',
      'spouse_phone' => 'Spouse-phone-number',
      'state' => 'province',
      'status' => 'status',
      'street' => 'street',
      'zip' => 'zip-code'
    }
  end

  let(:file_constants_mappings) do
    {
      'status' => {
        'partner_financial' => 'Praying and giving'
      },
      'commitment_frequency' => {
        '1_0' => 'Monthly'
      },
      'newsletter' => {
        'both' => 'Both'
      }
    }
  end

  let(:correct_attributes) do
    { file: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'sample_csv_to_import.csv')) }
  end

  let(:update_attributes) do
    {
      tag_list: 'test',
      updated_in_db_at: resource.updated_at
    }
  end

  let(:given_reference_key) { :file_url }

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
      }
    }
  end

  let(:incorrect_attributes) do
    { file: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'tnt', 'tnt_export.xml')) }
  end

  let(:unpermitted_attributes) { { file_headers: ['test'] } }

  context 'file uploading uses content type multipart form-data' do
    before(:each) { request.headers['CONTENT_TYPE'] = 'multipart/form-data' }

    include_examples 'create_examples'

    include_examples 'update_examples'
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  describe '#index' do
    it 'only returns imports with source csv' do
      create(:tnt_import, account_list: account_list, user: user)
      api_login(user)
      expect(account_list.imports.count).to eq(3)
      get :index, full_correct_attributes
      expect(JSON.parse(response.body)['data'].size).to eq(2)
    end

    it 'returns mappings without transforming their keys' do
      api_login(user)
      get :index, full_correct_attributes
      attributes = JSON.parse(response.body)['data'].first['attributes']
      expect(attributes['file_headers_mappings']).to eq file_headers_mappings
      expect(attributes['file_constants_mappings']).to eq file_constants_mappings
    end
  end

  describe '#show' do
    it 'does not return an import if it does not have source csv' do
      tnt_import = create(:tnt_import, account_list: account_list, user: user)
      api_login(user)
      get :show, parent_param.merge(id: tnt_import.uuid)
      expect(response.status).to eq(404)
    end
  end

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
      post :create, full_correct_attributes.tap { |params| params[:data][:attributes][:source] = 'twitter' }
      import = Import.find_by_uuid(JSON.parse(response.body)['data']['id'])
      expect(import.source).to eq 'csv'
    end

    it 'defaults in_preview to true' do
      api_login(user)
      post :create, full_correct_attributes.tap { |params| params[:data][:attributes].delete([:in_preview, 'in_preview']) }
      import = Import.find_by_uuid(JSON.parse(response.body)['data']['id'])
      expect(import.in_preview?).to eq true
    end

    it 'defaults user_id to current user' do
      api_login(user)
      full_correct_attributes[:data][:relationships].delete(:user)
      post :create, full_correct_attributes
      import = Import.find_by_uuid(JSON.parse(response.body)['data']['id'])
      expect(import.user_id).to eq user.id
    end

    it 'persists cached file data' do
      api_login(user)
      post :create, full_correct_attributes.tap { |params| params[:data][:attributes].delete([:in_preview, 'in_preview']) }
      import = Import.find_by_uuid(JSON.parse(response.body)['data']['id'])
      expect(import.file_headers).to be_present
      expect(import.file_headers).to be_a Hash
      expect(import.file_constants).to be_present
      expect(import.file_constants).to be_a Hash
      expect(import.file_row_samples).to be_present
      expect(import.file_row_samples).to be_a Array
    end

    it 'includes sample contacts' do
      api_login(user)
      post :create, (full_correct_attributes.tap do |params|
        params[:data][:attributes].delete([:in_preview, 'in_preview'])
        params[:include] = 'sample_contacts'
      end)
      included = JSON.parse(response.body)['included']
      expect(included.size).to eq 1
      expect(included.first['type']).to eq 'contacts'
    end
  end

  describe '#update' do
    it 'permits all params under file_headers_mappings' do
      api_login(user)
      put :update, full_correct_attributes.tap { |params|
        params[:data][:attributes][:file_headers_mappings] = { 'testing' => { 'nested' => '1234' } }
      }
      expect(import.reload.file_headers_mappings).to eq('testing' => { 'nested' => '1234' })
    end

    it 'permits all params under file_constants_mappings' do
      api_login(user)
      put :update, full_correct_attributes.tap { |params|
        params[:data][:attributes][:file_constants_mappings] = { 'testing' => { 'nested' => '1234' } }
      }
      expect(import.reload.file_constants_mappings).to eq('testing' => { 'nested' => '1234' })
    end

    it 'permits assigning empty hashes to the mappings' do
      api_login(user)
      import.update(file_constants_mappings: { 'testing' => '1234' }, file_headers_mappings: { 'testing' => '1234' })
      expect(import.reload.file_constants_mappings).to eq('testing' => '1234')
      expect(import.file_headers_mappings).to eq('testing' => '1234')
      put :update, full_correct_attributes.tap { |params|
        params[:data][:attributes][:file_constants_mappings] = params[:data][:attributes][:file_headers_mappings] = {}
      }
      expect(import.reload.file_constants_mappings).to eq({})
      expect(import.file_headers_mappings).to eq({})
    end
  end
end
