require 'rails_helper'

RSpec.describe Task::Filter::ContactTimezone do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, timezone: 'Mountain Time (US & Canada)') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, timezone: 'Eastern Time (US & Canada)') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, timezone: nil) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, timezone: nil) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_three]) }
  let!(:task_four) { create(:task, account_list: account_list, contacts: [contact_four]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_timezone: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_timezone: [] }, account_list)).to eq(nil)
      end
    end

    context 'filter task based on contact timezone' do
      it 'returns the tasks with contacts whose timezone matches the provided filter' do
        expect(described_class.query(tasks, { contact_timezone: 'Mountain Time (US & Canada)' }, account_list).to_a).to eq [task_one]
        expect(described_class.query(tasks, { contact_timezone: 'Eastern Time (US & Canada)' }, account_list).to_a).to eq [task_two]
      end
    end
  end
end
