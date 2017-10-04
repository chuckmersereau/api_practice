require 'rails_helper'

RSpec.describe Task::Filter::ContactStatus do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let!(:active_contact) { create(:contact, account_list: account_list, status: 'Ask in Future') }
  let!(:inactive_contact) { create(:contact, account_list: account_list, status: 'Not Interested') }
  let!(:contact_with_no_status) { create(:contact, account_list: account_list, status: nil) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [active_contact]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [inactive_contact]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_with_no_status]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'for single status' do
      it 'returns the correct tasks for corresponding contact status filter' do
        expect(described_class.query(tasks, { contact_status: 'active' }, account_list).to_a).to eq([task_one, task_three])
        expect(described_class.query(tasks, { contact_status: 'hidden' }, account_list).to_a).to eq([task_two])
        expect(described_class.query(tasks, { contact_status: 'null' }, account_list).to_a).to eq([task_three])
        expect(described_class.query(tasks, { contact_status: 'null' }, account_list).to_a).not_to match_array([task_one, task_two, task_three])
      end
    end

    context 'for multiple statuses' do
      it 'returns the correct contacts' do
        expect(described_class.query(tasks, { contact_status: 'active, hidden' }, account_list).to_a).to match_array([task_one, task_two, task_three])
        expect(described_class.query(tasks, { contact_status: 'hidden, null' }, account_list).to_a).to match_array([task_two, task_three])
        expect(described_class.query(tasks, { contact_status: 'null, hidden' }, account_list).to_a).not_to match_array([task_one, task_two, task_three])
      end
    end
  end
end
