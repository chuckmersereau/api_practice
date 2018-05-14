require 'rails_helper'

describe QueueContactDupMergeBatchWorker do
  let(:account_list) { create(:account_list) }
  let(:designation_account) { create(:designation_account) }
  let(:donor_account) { create(:donor_account) }
  let(:contact_one) { create(:contact, name: 'Joe', account_list: account_list) }
  let(:contact_two) { create(:contact, name: 'Joe', account_list: account_list) }
  let(:contact_three) { create(:contact, name: 'Jane', account_list: account_list) }
  let(:contact_four) { create(:contact, name: 'Jane', account_list: account_list) }

  before do
    Sidekiq::Testing.inline!
    account_list.designation_accounts << designation_account
    contact_one.donor_accounts << donor_account
    contact_two.donor_accounts << donor_account
    contact_three.donor_accounts << donor_account
    contact_four.donor_accounts << donor_account
  end

  it 'merges contact duplicates' do
    expect do
      QueueContactDupMergeBatchWorker.new.perform(account_list.id, 0)
    end.to change { account_list.reload.contacts.count }.from(4).to(2)
  end

  it 'does not queue duplicate jobs' do
    Sidekiq::Testing.fake!
    bid = QueueContactDupMergeBatchWorker.new.perform(account_list.id, 0)
    expect(Sidekiq::Batch::Status.new(bid).total).to eq(2)
  end

  it 'returns the batch id' do
    expect(QueueContactDupMergeBatchWorker.new.perform(account_list.id, 0)).to be_a(String)
  end

  it 'sets the batch description' do
    batch_status = Sidekiq::Batch::Status.new(QueueContactDupMergeBatchWorker.new.perform(account_list.id, 0))
    expected_description = "Merge duplicate Contacts for AccountList #{account_list.id} since 1970-01-01 00:00:00 UTC"
    expect(batch_status.description).to eq(expected_description)
  end

  it 'only merges contacts updated since the given time' do
    contact_three.update_column(:updated_at, 2.hours.ago)
    contact_four.update_column(:updated_at, 2.hours.ago)
    expect do
      QueueContactDupMergeBatchWorker.new.perform(account_list.id, 1.hour.ago)
    end.to change { account_list.reload.contacts.count }.from(4).to(3)
  end

  context 'account_list does not exist' do
    it 'returns successfully' do
      expect { QueueContactDupMergeBatchWorker.new.perform(1234, 0) }.to_not raise_error
    end
  end
end
