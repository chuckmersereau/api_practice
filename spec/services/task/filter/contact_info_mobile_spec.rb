require 'rails_helper'

RSpec.describe Task::Filter::ContactInfoMobile do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_three]) }
  let!(:task_four) { create(:task, account_list: account_list, contacts: [contact_four]) }

  let!(:person_one) { create(:person) }
  let!(:person_two) { create(:person) }

  let!(:phone_number_one)   { create(:phone_number, location: 'home') }
  let!(:phone_number_two)   { create(:phone_number, location: 'mobile') }
  let!(:phone_number_three) { create(:phone_number, location: 'work') }
  let!(:phone_number_four)  { create(:phone_number, location: 'mobile') }

  before do
    contact_one.people << person_one
    contact_two.people << person_two
    person_one.phone_numbers << phone_number_one
    person_one.phone_numbers << phone_number_two
    person_one.phone_numbers << phone_number_three
    person_two.phone_numbers << phone_number_four
  end

  describe '#query' do
    let(:tasks) { Task.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_mobile: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_mobile: [] }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_mobile: '' }, account_list)).to eq(nil)
      end
    end

    context 'filter by no mobile phone' do
      it 'returns only contacts that have no mobile phone' do
        expect(described_class.query(tasks, { contact_info_mobile: 'No' }, account_list).to_a).to match_array [task_three, task_four]
      end
    end

    context 'filter by mobile phone' do
      it 'returns only contacts that have a mobile phone' do
        expect(described_class.query(tasks, { contact_info_mobile: 'Yes' }, account_list).to_a).to match_array [task_one, task_two]
      end
    end
  end
end
