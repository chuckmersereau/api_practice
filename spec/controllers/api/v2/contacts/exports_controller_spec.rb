require 'rails_helper'
require 'tempfile'
require 'roo'

describe Api::V2::Contacts::ExportsController, type: :controller do
  let(:factory_type) { :contact }

  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let(:second_account_list) { create(:account_list, users: [user]) }

  let!(:contact) { create(:contact, account_list: account_list, name: 'Last Contact', primary_person: primary_person) }
  let!(:second_contact) { create(:contact, account_list: account_list, name: 'First Contact') }
  let!(:third_contact) { create(:contact, account_list: second_account_list, name: 'Missing Contact') }

  let!(:primary_person) { create(:person) }
  let!(:spouse_person) { create(:person, contacts: [contact]) }

  let!(:primary_email_address) { create(:email_address, primary: true, person: primary_person) }
  let!(:spouse_email_address) { create(:email_address, primary: true, person: spouse_person) }
  let!(:spouse_other_email_address) { create(:email_address, primary: false, person: spouse_person) }

  let!(:primary_phone_number) { create(:phone_number, primary: true, person: primary_person) }
  let!(:spouse_phone_number) { create(:phone_number, primary: true, person: spouse_person) }
  let!(:spouse_other_phone_number) { create(:phone_number, primary: false, person: spouse_person) }

  let(:id) { contact.uuid }

  render_views

  context 'CSV and XLSX export' do
    it 'does not shows resources to users that are not signed in' do
      [:csv, :xlsx].each do |format|
        get :index, format: format
        expect(response.status).to eq(401)
      end
    end

    it 'logs the export if successful' do
      api_login(user)

      [:csv, :xlsx].each do |format|
        expect do
          get :index, format: format
        end.to change { ExportLog.count }.by(1)

        expect(response.status).to eq(200)
      end
    end
  end

  context 'CSV export' do
    let(:contact_index) { response.body.index(contact.name) }
    let(:second_contact_index) { response.body.index(second_contact.name) }

    it 'renders the export sorted alphabetically for users that are signed in' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)
      expect(contact_index).to be_present
      expect(response.body).to be_present
      expect(contact_index).to be > second_contact_index
    end

    it 'renders the export with right contacts when contact_ids is provided' do
      api_login(user)
      get :index, format: :csv, filter: { ids: contact.uuid }
      expect(response.status).to eq(200)
      expect(contact_index).to be_present
      expect(response.body).to be_present
    end

    it 'allows filtering by account_list_id' do
      api_login(user)
      get :index, format: :csv, filter: { account_list_id: second_account_list.uuid }
      expect(response.status).to eq(200)
      expect(response.body).to include(third_contact.name)
      expect(response.body).to_not include(contact.name)
    end

    it 'renders both the primary person and spouse phone and email address' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)
      expect(response.body).to include('"Primary Email","Spouse Email","Other Email","Spouse Other Email"')
      expect(response.body).to include('"Primary Phone","Spouse Phone","Other Phone","Spouse Other Phone"')
      expect(response.body).to include("#{primary_email_address.email},#{spouse_email_address.email},,#{spouse_other_email_address.email}")
      expect(response.body).to include("#{primary_phone_number.number},#{spouse_phone_number.number},,#{spouse_other_phone_number.number}")
    end
  end

  context 'XLSX export' do
    let(:contact_index) { spreadsheet.to_csv.index(contact.name) }
    let(:second_contact_index) { spreadsheet.to_csv.index(second_contact.name) }
    let(:third_contact_index) { spreadsheet.to_csv.index(third_contact.name) }

    it 'renders the export sorted alphabetically for users that are signed in' do
      api_login(user)
      get :index, format: :xlsx
      expect(contact_index).to be_present
      expect(second_contact_index).to be_present
      expect(contact_index).to be > second_contact_index
    end

    it 'renders the export with right contacts when contact_ids is provided' do
      api_login(user)
      get :index, format: :xlsx, filter: { ids: contact.uuid }
      expect(response.status).to eq(200)
      expect(contact_index).to be_present
      expect(second_contact_index).to be_blank
    end

    it 'allows filtering by account_list_id' do
      api_login(user)
      get :index, format: :xlsx, filter: { account_list_id: second_account_list.uuid }
      expect(response.status).to eq(200)
      expect(contact_index).to be_blank
      expect(third_contact_index).to be_present
    end

    it 'renders both the primary person and spouse phone and email address' do
      api_login(user)
      get :index, format: :xlsx
      expect(response.status).to eq(200)
      expect(spreadsheet.to_csv).to include('"Primary Email","Spouse Email","Other Email","Spouse Other Email"')
      expect(spreadsheet.to_csv).to include('"Primary Phone","Spouse Phone","Other Phone","Spouse Other Phone"')
      expect(spreadsheet.to_csv).to include("#{primary_email_address.email}\",\"#{spouse_email_address.email}\",,\"#{spouse_other_email_address.email}")
      expect(spreadsheet.to_csv).to include("#{primary_phone_number.number}\",\"#{spouse_phone_number.number}\",,\"#{spouse_other_phone_number.number}")
    end
  end

  def spreadsheet
    temp_xlsx = Tempfile.new('temp')
    temp_xlsx.write(response.body)
    temp_xlsx.rewind
    Roo::Spreadsheet.open(temp_xlsx.path, extension: :xlsx)
  end
end
