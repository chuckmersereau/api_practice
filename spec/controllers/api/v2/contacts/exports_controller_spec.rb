require 'spec_helper'
require 'tempfile'
require 'roo'

describe Api::V2::Contacts::ExportsController, type: :controller do
  let(:factory_type) { :contact }

  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:second_contact) { create(:contact, account_list: account_list) }

  let(:id) { contact.uuid }

  render_views

  context 'CSV and XLSX export' do
    it 'does not shows resources to users that are not signed in' do
      [:csv, :xlsx].each do |format|
        get :index, format: format
        expect(response.status).to eq(401)
      end
    end
  end

  context 'CSV export' do
    it 'renders the export for users that are signed in' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)
      expect(response.body).to include(contact.name)
      expect(response.body).to include(second_contact.name)
    end

    it 'renders the export with right contacts when contact_ids is provided' do
      api_login(user)
      get :index, format: :csv, filter: { ids: contact.uuid }
      expect(response.status).to eq(200)
      expect(response.body).to include(contact.name)
      expect(response.body).to_not include(second_contact.name)
    end
  end

  context 'XLSX export' do
    it 'renders the export for users that are signed in' do
      api_login(user)
      get :index, format: :xlsx
      expect(response.status).to eq(200)
      expect(spreadsheet.to_csv).to include(contact.name)
      expect(spreadsheet.to_csv).to include(second_contact.name)
    end

    it 'renders the export with right contacts when contact_ids is provided' do
      api_login(user)
      get :index, format: :xlsx, filter: { ids: contact.uuid }
      expect(response.status).to eq(200)
      expect(spreadsheet.to_csv).to include(contact.name)
      expect(spreadsheet.to_csv).to_not include(second_contact.name)
    end
  end

  def spreadsheet
    temp_xlsx = Tempfile.new('temp')
    temp_xlsx.write(response.body)
    temp_xlsx.rewind
    Roo::Spreadsheet.open(temp_xlsx.path, extension: :xlsx)
  end
end
