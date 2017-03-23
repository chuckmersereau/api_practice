require 'rails_helper'
require 'tempfile'
require 'roo'

describe Api::V2::Contacts::Exports::MailingController, type: :controller do
  let(:factory_type) { :contact }

  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:contact) { create(:contact, account_list: account_list, addresses: [build(:address)]) }
  let!(:second_contact) { create(:contact, account_list: account_list, addresses: [build(:address, street: '123 another street')]) }

  let(:id) { contact.uuid }

  render_views

  context 'Mailing CSV export' do
    it 'does not shows resources to users that are not signed in' do
      get :index, format: :csv
      expect(response.status).to eq(401)
    end

    it 'renders the export for users that are signed in' do
      api_login(user)
      get :index, format: :csv
      expect(response.status).to eq(200)
      expect(response.body).to include(contact.name)
      expect(response.body).to include(contact.csv_street)
      expect(response.body).to include(second_contact.name)
      expect(response.body).to include(second_contact.csv_street)
    end

    it 'renders the export with right contacts when contact_ids is provided' do
      api_login(user)
      get :index, format: :csv, filter: { ids: contact.uuid }
      expect(response.status).to eq(200)
      expect(response.body).to include(contact.name)
      expect(response.body).to include(contact.csv_street)
      expect(response.body).to_not include(second_contact.name)
      expect(response.body).to_not include(second_contact.csv_street)
    end
  end
end
