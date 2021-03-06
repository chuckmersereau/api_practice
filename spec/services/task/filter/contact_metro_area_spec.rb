require 'rails_helper'

RSpec.describe Task::Filter::ContactMetroArea do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }
  let!(:contact_five)  { create(:contact, account_list_id: account_list.id) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_three]) }
  let!(:task_four) { create(:task, account_list: account_list, contacts: [contact_four]) }
  let!(:task_five) { create(:task, account_list: account_list, contacts: [contact_five]) }

  let!(:address_one)   { create(:address, metro_area: 'My Metro') }
  let!(:address_two)   { create(:address, metro_area: 'My Metro') }
  let!(:address_three) { create(:address, metro_area: nil) }
  let!(:address_four)  { create(:address, metro_area: nil) }
  let!(:address_five)  { create(:address, metro_area: 'My Metro', historic: true) }

  before do
    contact_one.addresses << address_one
    contact_two.addresses << address_two
    contact_three.addresses << address_three
    contact_four.addresses << address_four
    contact_five.addresses << address_five
  end

  describe '#query' do
    let(:tasks) { Task.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_metro_area: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_metro_area: [] }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_metro_area: '' }, account_list)).to eq(nil)
      end
    end

    context 'filter by no metro_area' do
      it 'returns only tasks with contacts that have no metro_area' do
        result = described_class.query(tasks, { contact_metro_area: 'none' }, account_list).to_a

        expect(result).to match_array [task_three, task_four]
      end
    end

    context 'filter by metro_area' do
      it 'filters multiple metro_areas' do
        result = described_class.query(tasks, { contact_metro_area: 'My Metro, My Metro' }, account_list).to_a

        expect(result).to match_array [task_one, task_two]
      end
      it 'filters a single metro_area' do
        result = described_class.query(tasks, { contact_metro_area: 'My Metro' }, account_list).to_a

        expect(result).to match_array [task_one, task_two]
      end
    end

    context 'multiple filters' do
      it 'returns tasks with contacts matching multiple filters' do
        result = described_class.query(tasks, { contact_metro_area: 'My Metro, none' }, account_list).to_a

        expect(result).to match_array [task_one, task_two, task_three, task_four]
      end
    end

    context 'address historic' do
      it 'returns tasks with contacts matching the metro_area with historic addresses' do
        query = { contact_metro_area: 'My Metro', address_historic: 'true' }
        result = described_class.query(tasks, query, account_list).to_a

        expect(result).to eq [task_five]
      end
    end
  end
end
