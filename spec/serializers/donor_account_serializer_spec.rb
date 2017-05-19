require 'rails_helper'

describe DonorAccountSerializer do
  let(:account_list) { create(:account_list) }
  let(:contact_one) { create(:contact) }
  let(:contact_two) { create(:contact, account_list: account_list) }
  let(:donor_account) { create(:donor_account, contacts: [contact_one, contact_two]) }
  let(:serialized_donor_account) { described_class.new(donor_account) }
  let(:scoped_donor_account) { described_class.new(donor_account, scope: { account_list: account_list }) }

  describe '#contacts' do
    context 'account list' do
      it 'only returns contacts associated to a specific account_list' do
        expect(scoped_donor_account.contacts).to eq([contact_two])
      end
    end
    context 'no account list' do
      it 'returns empty array' do
        expect(serialized_donor_account.contacts).to eq([])
      end
    end
  end

  describe '#display_name' do
    context 'account list' do
      context 'donor_account has associated contact' do
        it 'returns contact name (number)' do
          expect(scoped_donor_account.display_name).to eq "#{contact_two.name} (#{donor_account.account_number})"
        end
      end
      context 'donor_account has no associated contact' do
        context 'donor_account has name' do
          let(:donor_account) { create(:donor_account) }
          it 'returns donor_account name (number)' do
            expect(scoped_donor_account.display_name).to eq "#{donor_account.name} (#{donor_account.account_number})"
          end
        end
        context 'donor_account has no name' do
          let(:donor_account) { create(:donor_account, name: nil) }
          it 'returns donor_account number' do
            expect(scoped_donor_account.display_name).to eq donor_account.account_number
          end
        end
      end
    end
  end
end
