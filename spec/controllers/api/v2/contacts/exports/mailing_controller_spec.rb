require 'rails_helper'
require 'tempfile'
require 'roo'

describe Api::V2::Contacts::Exports::MailingController, type: :controller do
  let(:factory_type) { :contact }

  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let(:second_account_list) { create(:account_list, users: [user]) }

  let!(:contact) { create(:contact, account_list: account_list, name: 'Last Contact', addresses: [build(:address)]) }
  let!(:second_contact) { create(:contact, account_list: account_list, name: 'First Contact', addresses: [build(:address, street: '123 another street')]) }
  let!(:third_contact) { create(:contact, account_list: second_account_list, name: 'Missing Contact') }

  let(:id) { contact.uuid }

  render_views

  context 'Mailing CSV export' do
    let(:contact_index) { response.body.index(contact.name) }
    let(:second_contact_index) { response.body.index(contact.name) }

    it 'does not shows resources to users that are not signed in' do
      get :index, format: :csv
      expect(response.status).to eq(401)
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
      get :index, format: :csv, filter: { ids: contact.uuid }
      expect(response.status).to eq(200)
      expect(contact_index).to be_present
      expect(response.body).to be_present
      expect(response.body).to include(contact.csv_street)
      expect(response.body).to_not include(second_contact.csv_street)
    end

    it 'allows filtering by account_list_id' do
      api_login(user)
      get :index, format: :csv, filter: { account_list_id: second_account_list.uuid }
      expect(response.status).to eq(200)
      expect(response.body).to include(third_contact.name)
      expect(response.body).to_not include(contact.name)
    end
  end
end