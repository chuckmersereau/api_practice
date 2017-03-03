require 'rails_helper'

describe ScopedDonorAccount do
  let(:account_list) { create(:account_list) }
  let(:contact_one) { create(:contact) }
  let(:contact_two) { create(:contact, account_list: account_list) }
  let(:donor_account) { create(:donor_account, contacts: [contact_one, contact_two]) }
  let(:scoped_donor_account) { described_class.new(account_list: account_list, donor_account: donor_account) }

  describe '#contacts' do
    it 'only returns contacts associated to a specific account_list' do
      expect(scoped_donor_account.contacts).to eq([contact_two])
    end
  end
end
