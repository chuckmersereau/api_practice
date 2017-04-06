require 'rails_helper'

RSpec.describe ContactDetailSerializer, type: :serializer do
  describe 'lifetikme_donations' do
    let(:designation_account) { create(:designation_account) }
    let(:account_list) { create(:account_list, designation_accounts: [designation_account]) }

    let(:contact) { create(:contact, account_list: account_list) }
    let(:donor_account) { create(:donor_account, contacts: [contact]) }

    let!(:donation_one) { create(:donation, donor_account: donor_account, designation_account: designation_account, amount: 80.0) }
    let!(:donation_two) { create(:donation, donor_account: donor_account, designation_account: designation_account, amount: 140.0) }

    let(:serializer) { ContactDetailSerializer.new(contact) }
    let(:parsed_json_response) { JSON.parse(serializer.to_json) }

    it 'outputs the successes and failures in the correct format' do
      expect(parsed_json_response['lifetime_donations']).to eq('220.0')
    end
  end
end
