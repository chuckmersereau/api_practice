require 'rails_helper'

RSpec.describe Task::Filter::ContactChurch do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, church_name: 'My Church') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, church_name: 'First Pedestrian Church') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, church_name: nil) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, church_name: nil) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_three]) }
  let!(:task_four) { create(:task, account_list: account_list, contacts: [contact_four]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { church: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { church: [] }, account_list)).to eq(nil)
      end
    end

    context 'filter by no church' do
      it 'returns only tasks with  contacts that have no church' do
        expect(described_class.query(tasks, { contact_church: 'none' }, account_list).to_a).to match_array [task_three, task_four]
      end
    end

    context 'filter by church' do
      it 'filters multiple churches' do
        expect(described_class.query(tasks, { contact_church: 'My Church, First Pedestrian Church' }, account_list).to_a).to match_array [task_one, task_two]
      end
      it 'filters a single church' do
        expect(described_class.query(tasks, { contact_church: 'My Church' }, account_list).to_a).to eq [task_one]
      end
    end

    context 'multiple filters' do
      it 'returns tasks with contacts matching multiple filters' do
        expect(described_class.query(tasks, { contact_church: 'My Church, none' }, account_list).to_a).to match_array [task_one, task_three, task_four]
      end
    end
  end
end
