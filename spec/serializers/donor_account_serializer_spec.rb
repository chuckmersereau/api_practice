require 'rails_helper'

describe DonorAccountSerializer do
  let(:account_list) { create(:account_list) }
  let(:contact_one) { create(:contact) }
  let(:contact_two) { create(:contact, account_list: account_list) }
  let(:donor_account) { create(:donor_account, contacts: [contact_one, contact_two]) }
  let(:serializer) { described_class.new(donor_account) }
  let(:scoped_serializer) { described_class.new(donor_account, scope: { account_list: account_list }) }

  describe '#contacts' do
    context 'account list' do
      it 'only returns contacts associated to a specific account_list' do
        expect(scoped_serializer.contacts).to eq([contact_two])
      end
    end
    context 'no account list' do
      it 'returns empty array' do
        expect(serializer.contacts).to eq([])
      end
    end
  end

  describe '#display_name' do
    context 'donor_account has name and number' do
      let(:donor_account) { create(:donor_account, name: 'Name', account_number:  'Number') }
      it 'returns donor_account name (number)' do
        expect(serializer.display_name).to eq 'Name (Number)'
      end
    end
    context 'donor_account has name with number and number' do
      let(:donor_account) { create(:donor_account, name: 'Name Number', account_number:  'Number') }
      it 'returns donor_account name' do
        expect(serializer.display_name).to eq 'Name Number'
      end
    end
    context 'donor_account has no name' do
      let(:donor_account) { create(:donor_account, name: nil, account_number: 'Number') }
      it 'returns donor_account number' do
        expect(serializer.display_name).to eq 'Number'
      end
    end
    context 'donor_account has associated contact' do
      it 'returns contact name (number)' do
        expect(scoped_serializer.display_name).to eq "#{contact_two.name} (#{donor_account.account_number})"
      end
    end
  end
end
