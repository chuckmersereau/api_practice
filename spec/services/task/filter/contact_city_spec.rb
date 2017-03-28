require 'rails_helper'

RSpec.describe Task::Filter::ContactCity do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

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

  let!(:address_one)   { create(:address) }
  let!(:address_two)   { create(:address) }
  let!(:address_three) { create(:address, city: nil) }
  let!(:address_four)  { create(:address, city: nil) }
  let!(:address_five)  { create(:address, historic: true) }

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
        expect(described_class.query(tasks, { contact_city: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_city: [] }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_city: '' }, account_list)).to eq(nil)
      end
    end

    context 'filter by no city' do
      it 'returns only tasks with contacts that have no city' do
        expect(described_class.query(tasks, { contact_city: 'none' }, account_list).to_a).to include(task_three, task_four)
      end
    end

    context 'filter by city' do
      it 'filters multiple cities' do
        expect(described_class.query(tasks, { contact_city: 'Fremont, Fremont' }, account_list).to_a).to include(task_one, task_two)
      end
      it 'filters a single cities' do
        expect(described_class.query(tasks, { contact_city: 'Fremont' }, account_list).to_a).to include(task_one, task_two)
      end
    end

    context 'multiple filters' do
      it 'returns tasks with contacts matching multiple filters' do
        expect(described_class.query(tasks, { contact_city: 'Fremont, none' }, account_list).to_a).to include(task_one, task_two, task_three, task_four)
      end
    end

    context 'address historic' do
      it 'returns tasks with contacts matching the city with historic addresses' do
        expect(described_class.query(tasks, { contact_city: 'Fremont', address_historic: 'true' }, account_list).to_a).to include(task_five)
      end
    end
  end
end
