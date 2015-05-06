require 'spec_helper'

describe ImportsController do
  let(:file) { fixture_file_upload('/sample_csv_to_import.csv', 'text/csv') }

  before(:each) do
    @user = create(:user_with_account)
    @account_list = @user.account_lists.first
    sign_in(:user, @user)
    request.env['HTTP_REFERER'] = '/'
  end

  context '#create' do
    it 'handles a file upload and redirects back' do
      post :create, import: { file: file, source: 'csv' }
      expect(Import.count).to eq(1)
      expect(response).to redirect_to('/')
      expect(flash[:notice]).to be_present
    end

    it 'redirects to the import path if import is in preview' do
      post :create, import: { file: file, in_preview: true, source: 'csv' }
      expect(response).to redirect_to("/imports/#{Import.first.id}")
    end
  end

  context '#show' do
    it 'finds an import' do
      import = create(:csv_import, account_list: @account_list)
      get :show, id: import.id
      expect(response).to be_success
      expect(assigns(:import)).to eq(import)
    end

    it 'raises error if none found' do
      expect { get :show, id: 1 }.to raise_error
    end
  end

  context '#update' do
    let!(:import) { create(:csv_import, source: 'csv', in_preview: true, account_list: @account_list) }

    it 'updates an import and back to import edit page if in preview' do
      post :update, id: import.id, import: { tags: 'test', file: file }
      expect(response).to redirect_to("/imports/#{import.id}")
      expect(import.reload.tags).to eq('test')
    end

    it 'updates an import and redirects to accounts if not in preview' do
      post :update, id: import.id, import: { tags: 'test', in_preview: false, file: file }
      expect(response).to redirect_to('/accounts')
      expect(flash[:notice]).to be_present
      expect(import.reload.tags).to eq('test')
    end
  end
end
