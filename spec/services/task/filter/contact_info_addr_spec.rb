require 'rails_helper'

RSpec.describe Task::Filter::ContactInfoAddr do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_three]) }

  let!(:address_one) { create(:address) }

  before do
    contact_one.addresses << address_one
  end

  describe '#query' do
    let(:tasks) { Task.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_addr: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_addr: [] }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_addr: '' }, account_list)).to eq(nil)
      end
    end

    context 'filter by no address' do
      it 'returns only contacts that have no address' do
        expect(described_class.query(tasks, { contact_info_addr: 'No' }, account_list).to_a).to match_array [task_two, task_three]
      end
    end

    context 'filter by address' do
      it 'returns only contacts that have a address' do
        expect(described_class.query(tasks, { contact_info_addr: 'Yes' }, account_list).to_a).to eq [task_one]
      end
    end
  end
end
