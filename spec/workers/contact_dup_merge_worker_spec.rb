require 'rails_helper'

describe ContactDupMergeWorker do
  let(:account_list) { create(:account_list) }
  let(:designation_account) { create(:designation_account) }
  let(:donor_account) { create(:donor_account) }
  let(:contact_one) { create(:contact, name: 'Tester', account_list: account_list) }
  let(:contact_two) { create(:contact, name: 'Tester', account_list: account_list) }

  before do
    account_list.designation_accounts << designation_account
    contact_one.donor_accounts << donor_account
    contact_two.donor_accounts << donor_account
  end

  it 'merges contact duplicates' do
    expect do
      ContactDupMergeWorker.new.perform(account_list.id, contact_one.id)
    end.to change { account_list.reload.contacts.count }.from(2).to(1)
  end

  context 'account_list and contact do not exist' do
    it 'returns successfully' do
      expect { ContactDupMergeWorker.new.perform(1234, 5678) }.to_not raise_error
    end
  end
end
