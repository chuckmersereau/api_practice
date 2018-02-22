require 'rails_helper'

describe Api::V2::AccountLists::PrayerLettersAccountsController, type: :controller do
  let(:factory_type) { :prayer_letters_account }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list: account_list, send_newsletter: 'Both') }

  let!(:resource) { create(:prayer_letters_account, account_list: account_list) }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:prayer_letters_account) }
  let(:incorrect_attributes) { attributes_for(:prayer_letters_account, oauth2_token: nil) }

  include_examples 'show_examples'

  include_examples 'destroy_examples'

  describe '#create' do
    before do
      resource.destroy
    end

    include_examples 'create_examples'
  end

  describe '#sync' do
    before do
      api_login(user)
    end
    it 'syncs prayer letters account' do
      expect(response.status).to eq 200
    end
  end
end
