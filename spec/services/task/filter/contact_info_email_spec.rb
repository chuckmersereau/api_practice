require 'rails_helper'

RSpec.describe Task::Filter::ContactInfoEmail do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }

  let!(:person_one) { create(:person) }
  let!(:person_two) { create(:person) }

  let!(:email_address_one) { create(:email_address) }

  before do
    contact_one.people << person_one
    contact_two.people << person_two
    person_one.email_addresses << email_address_one
  end

  describe '#query' do
    let(:tasks) { Task.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_email: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_email: [] }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_email: '' }, account_list)).to eq(nil)
      end
    end

    context 'filter by no address' do
      it 'returns only contacts that have no address' do
        expect(described_class.query(tasks, { contact_info_email: 'No' }, account_list).to_a).to match_array [task_two]
      end
    end

    context 'filter by address' do
      it 'returns only contacts that have a address' do
        expect(described_class.query(tasks, { contact_info_email: 'Yes' }, account_list).to_a).to match_array [task_one]
      end
    end
  end
end
