require 'rails_helper'

RSpec.describe Task::Filter::ContactPledgeFrequency do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let!(:frequent_contact) { create(:contact, account_list: account_list, pledge_frequency: 1) }
  let!(:infrequent_contact) { create(:contact, account_list: account_list, pledge_frequency: nil) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [frequent_contact]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [infrequent_contact]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_pledge_frequency: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_pledge_frequency: [] }, account_list)).to eq(nil)
      end
    end

    context 'filter by contact with a pledge frequecy' do
      it 'returns the tasks with contacts that have a pledge frequency set' do
        expect(described_class.query(tasks, { contact_pledge_frequency: '1' }, account_list).to_a).to eq [task_one]
        expect(described_class.query(tasks, { contact_pledge_frequency: '1' }, account_list).to_a).not_to match_array [task_one, task_two]
      end
    end
  end
end
