require 'spec_helper'

describe Api::V1::AppealExclusionsController do
  describe 'api' do
    let(:user) { create(:user_with_account) }
    let(:account_list) { user.account_lists.first }
    let(:appeal) { create(:appeal, account_list: account_list) }
    let(:contact) { create(:contact, account_list: account_list) }

    before do
      appeal.excluded_appeal_contacts.create(contact: contact, reasons: ['recent_increase'])
    end

    it 'gets excluded contacts' do
      get :index, access_token: user.access_token, appeal_id: appeal.id

      expect(response).to be_success
      json = JSON.parse(response.body)['appeal_exclusions']
      expect(json.length).to eq(1)
      expect(json[0].keys).to include 'contact'
      expect(json[0].keys).to include 'reasons'
    end
  end
end
