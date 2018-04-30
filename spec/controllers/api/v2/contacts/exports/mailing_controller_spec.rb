require 'rails_helper'
require 'tempfile'
require 'roo'

describe Api::V2::Contacts::Exports::MailingController, type: :controller do
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

  let!(:contact) { create(:contact, account_list: account_list, name: 'Last Contact', addresses: [build(:address)]) }
  let!(:second_contact) do
    create(:contact, account_list: account_list,
                     name: 'First Contact',
                     addresses: [build(:address, street: '123 another street')])
  end
  let!(:third_contact) { create(:contact, account_list: second_account_list, name: 'Missing Contact') }

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
  end

  render_views

  context 'Mailing CSV export' do
    let(:contact_index) { response.body.index(contact.name) }
    let(:second_contact_index) { response.body.index(contact.name) }

    it 'does not shows resources to users that are not signed in' do
      get :index, format: :csv
      expect(response.status).to eq(401)
    end

    it 'logs the export if successful' do
      api_login(user)
      expect do
        get :index, format: :csv
      end.to change { ExportLog.count }.from(0).to(1)
      expect(response.status).to eq(200)
      expect(ExportLog.first.active).to eq(false)
      expect(ExportLog.first.type).to eq('Contacts Mailing')
    end

    it 'renders the export alphabetically for users that are signed in' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)
      expect(contact_index).to be_present
      expect(response.body).to be_present
      expect(contact_index).to be > response.body.index(second_contact.name)
      expect(response.body).to include(contact.csv_street)
      expect(response.body).to include(second_contact.csv_street)
    end

    it 'renders the export with right contacts when contact_ids is provided' do
      api_login(user)
      get :index, format: :csv, filter: { ids: contact.id }
      expect(response.status).to eq(200)
      expect(contact_index).to be_present
      expect(response.body).to be_present
      expect(response.body).to include(contact.csv_street)
      expect(response.body).to_not include(second_contact.csv_street)
    end

    it 'allows filtering by account_list_id' do
      api_login(user)
      get :index, format: :csv, filter: { account_list_id: second_account_list.id }
      expect(response.status).to eq(200)
      expect(response.body).to include(third_contact.name)
      expect(response.body).to_not include(contact.name)
    end

    it 'allows filtering by status' do
      filters = { status: 'Call for Decision' }
      api_login(user)

      get :index, format: :csv, filter: filters

      expect(response.status).to eq(200)
    end
  end
end
