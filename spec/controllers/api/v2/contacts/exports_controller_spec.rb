require 'rails_helper'
require 'tempfile'
require 'roo'

describe Api::V2::Contacts::ExportsController, type: :controller do
  let(:factory_type) { :contact }

  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let(:second_account_list) { create(:account_list, users: [user]) }
  let(:resource) { create(:export_log, user: user) }
  let(:id) { resource.id }
  let(:incorrect_attributes) { nil }
  let(:correct_attributes) do
    {
      params: {
        filter: {
          status: 'active'
        }
      }
    }
  end

  let!(:contact) { create(:contact, account_list: account_list, name: 'Last Contact', primary_person: primary_person) }
  let!(:second_contact) { create(:contact_with_person, account_list: account_list, name: 'First Contact') }
  let!(:third_contact) { create(:contact_with_person, account_list: second_account_list, name: 'Missing Contact') }

  let!(:primary_person) { create(:person, first_name: 'Bill') }
  let!(:spouse_person) { create(:person, contacts: [contact], first_name: 'Vonette') }

  let!(:primary_email_address) { create(:email_address, primary: true, person: primary_person) }
  let!(:spouse_email_address) { create(:email_address, primary: true, person: spouse_person) }
  let!(:spouse_other_email_address) { create(:email_address, primary: false, person: spouse_person) }

  let!(:primary_phone_number) { create(:phone_number, primary: true, person: primary_person) }
  let!(:spouse_phone_number) { create(:phone_number, primary: true, person: spouse_person) }
  let!(:spouse_other_phone_number) { create(:phone_number, primary: false, person: spouse_person) }

  let(:expected_headers1) { '"Primary Email","Spouse Email","Other Email","Spouse Other Email"' }
  let(:expected_headers2) { '"Primary Phone","Spouse Phone","Other Phone","Spouse Other Phone"' }

  include_examples 'show_examples'
  include_examples 'create_examples'

  describe '#show' do
    it 'only allows export display to occur once' do
      api_login(user)
      get :show, id: resource.id
      expect(response.status).to eq(200)
      get :show, id: resource.id
      expect(response.status).to eq(403)
    end

    it 'sets active to false' do
      api_login(user)
      get :show, id: resource.id
      expect(resource.reload.active).to eq(false)
    end

    it 'uses contact filtering instead of generic filtering' do
      resource.update(
        params: {
          filter: {
            donation_amount_range: {
              min: '500'
            },
            account_list_id: account_list_id,
            any_tags: false
          }
        }.to_json
      )

      api_login(user)
      get :show, id: resource.id, format: :csv
      expect(response.status).to eq(200)
    end
  end

  render_views

  context 'CSV and XLSX export' do
    it 'does not shows resources to users that are not signed in' do
      [:csv, :xlsx].each do |format|
        get :index, format: format
        expect(response.status).to eq(401)
      end
    end

    it 'logs the CSV export if successful' do
      api_login(user)
      expect do
        get :index, format: :csv
      end.to change { ExportLog.count }.from(0).to(1)
      expect(response.status).to eq(200)
      expect(ExportLog.first.active).to eq(false)
    end

    it 'logs the XLSX export if successful' do
      api_login(user)
      expect do
        get :index, format: :xlsx
      end.to change { ExportLog.count }.from(0).to(1)
      expect(response.status).to eq(200)
      expect(ExportLog.first.active).to eq(false)
      expect(ExportLog.first.type).to eq('Contacts')
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
      get :index, format: :csv, filter: { ids: contact.id }
      expect(response.status).to eq(200)
      expect(contact_index).to be_present
      expect(response.body).to be_present
    end

    it 'allows filtering by account_list_id' do
      api_login(user)
      get :index, format: :csv, filter: { account_list_id: second_account_list.id }
      expect(response.status).to eq(200)
      expect(response.body).to include(third_contact.name)
      expect(response.body).to_not include(contact.name)
    end

    it 'renders both the primary person and spouse phone and email address' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)
      expect(response.body).to include(expected_headers1)
      expect(response.body).to include(expected_headers2)
      email_addresses = "#{primary_email_address.email},#{spouse_email_address.email}"\
                        ",,#{spouse_other_email_address.email}"
      expect(response.body).to include(email_addresses)
      phone_numbers = "#{primary_phone_number.number},#{spouse_phone_number.number}"\
                      ",,#{spouse_other_phone_number.number}"
      expect(response.body).to include(phone_numbers)
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
      get :index, format: :xlsx, filter: { ids: contact.id }
      expect(response.status).to eq(200)
      expect(contact_index).to be_present
      expect(second_contact_index).to be_blank
    end

    it 'allows filtering by account_list_id' do
      api_login(user)
      get :index, format: :xlsx, filter: { account_list_id: second_account_list.id }
      expect(response.status).to eq(200)
      expect(contact_index).to be_blank
      expect(third_contact_index).to be_present
    end

    it 'renders both the primary person and spouse phone and email address' do
      api_login(user)
      get :index, format: :xlsx
      expect(response.status).to eq(200)
      expect(spreadsheet.to_csv).to include(expected_headers1)
      expect(spreadsheet.to_csv).to include(expected_headers2)
      email_addresses = "#{primary_email_address.email}\",\"#{spouse_email_address.email}\""\
                        ",,\"#{spouse_other_email_address.email}"
      expect(spreadsheet.to_csv).to include(email_addresses)
      phone_numbers = "#{primary_phone_number.number}\",\"#{spouse_phone_number.number}\""\
                      ",,\"#{spouse_other_phone_number.number}"
      expect(spreadsheet.to_csv).to include(phone_numbers)
    end
  end

  context 'Primary Person is deceased' do
    before { primary_person.update!(deceased: true) }

    it 'renders only the spouse as the primary person' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)

      row = CSV.parse(response.body, headers: true).find { |r| r['Contact Name'] == contact.name }
      expect(row).to_not be nil
      expect(row.to_hash).to include('First Name' => 'Vonette',
                                     'Last Name' => spouse_person.last_name,
                                     'Primary Email' => spouse_email_address.email,
                                     'Spouse Email' => nil,
                                     'Other Email' => spouse_other_email_address.email,
                                     'Spouse Other Email' => nil,
                                     'Primary Phone' => spouse_phone_number.number,
                                     'Spouse Phone' => nil,
                                     'Other Phone' => spouse_other_phone_number.number,
                                     'Spouse Other Phone' => nil)
    end
  end

  context 'Spouse is deceased' do
    before { spouse_person.update!(deceased: true) }

    it 'renders only the primary person phone and email address' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)

      row = CSV.parse(response.body, headers: true).find { |r| r['Contact Name'] == contact.name }
      expect(row).to_not be nil
      expect(row.to_hash).to include('First Name' => 'Bill',
                                     'Last Name' => primary_person.last_name,
                                     'Primary Email' => primary_email_address.email,
                                     'Spouse Email' => nil,
                                     'Other Email' => nil,
                                     'Spouse Other Email' => nil,
                                     'Primary Phone' => primary_phone_number.number,
                                     'Spouse Phone' => nil,
                                     'Other Phone' => nil,
                                     'Spouse Other Phone' => nil)
    end
  end

  context 'Both Primary Person and Spouse are deceased' do
    before { primary_person.update!(deceased: true) }
    before { spouse_person.update!(deceased: true) }

    it 'does not render the row at all' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)

      row = CSV.parse(response.body, headers: true).find { |r| r['Contact Name'] == contact.name }
      expect(row).to be nil
    end
  end

  def spreadsheet
    temp_xlsx = Tempfile.new('temp')
    temp_xlsx.write(response.body)
    temp_xlsx.rewind
    Roo::Spreadsheet.open(temp_xlsx.path, extension: :xlsx)
  end
end
