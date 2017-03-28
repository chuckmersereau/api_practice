require 'rails_helper'

RSpec.describe Task::Filter::ContactNewsletter do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let!(:email_contact) { create(:contact, account_list: account_list, send_newsletter: 'Email') }
  let!(:physical_contact) { create(:contact, account_list: account_list, send_newsletter: 'Physical') }
  let!(:both_contact) { create(:contact, account_list: account_list, send_newsletter: 'Both') }
  let!(:nil_contact) { create(:contact, account_list: account_list, send_newsletter: nil) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [email_contact]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [physical_contact]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [both_contact]) }
  let!(:task_four) { create(:task, account_list: account_list, contacts: [nil_contact]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { newsletter: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { newsletter: [] }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { newsletter: '' }, account_list)).to eq(nil)
      end
    end

    context 'filter by contact newsletter none' do
      it 'returns only tasks with contacts that have no newsletter option selected' do
        expect(described_class.query(tasks, { contact_newsletter: 'none' }, account_list).to_a).to match_array [task_four]
      end
    end
    context 'filter by contact newsletter all' do
      it 'returns all tasks with contacts that have any newsletter option selected, but not blank' do
        expect(described_class.query(tasks, { contact_newsletter: 'all' }, account_list).to_a).to match_array [task_one, task_two, task_three]
      end
    end
    context 'filter by contact newsletter physical' do
      it 'returns all tasks with contacts that have physical or both newsletter options selected' do
        expect(described_class.query(tasks, { contact_newsletter: 'address' }, account_list).to_a).to match_array [task_two, task_three]
      end
    end
    context 'filter by contact newsletter email' do
      it 'returns all tasks with contacts that have email or both newsletter options selected' do
        expect(described_class.query(tasks, { contact_newsletter: 'email' }, account_list).to_a).to match_array [task_one, task_three]
      end
    end
    context 'filter by contact newsletter both' do
      it 'returns all tasks with contacts that have both newsletter options selected' do
        expect(described_class.query(tasks, { contact_newsletter: 'both' }, account_list).to_a).to match_array [task_three]
      end
    end
  end
end
