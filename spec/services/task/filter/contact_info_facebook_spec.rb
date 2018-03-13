require 'rails_helper'

RSpec.describe Task::Filter::ContactInfoFacebook do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }

  let!(:person_one) { create(:person) }
  let!(:person_two) { create(:person) }

  let!(:facebook_account_one) { create(:facebook_account, person: person_one) }

  before do
    contact_one.people << person_one
    contact_two.people << person_two
  end

  describe '#query' do
    let(:tasks) { Task.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_facebook: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_facebook: [] }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_info_facebook: '' }, account_list)).to eq(nil)
      end
    end

    context 'filter by no address' do
      it 'returns only contacts that have no address' do
        expect(described_class.query(tasks, { contact_info_facebook: 'No' }, account_list).to_a).to eq [task_two]
      end
    end

    context 'filter by address' do
      it 'returns only contacts that have a address' do
        expect(described_class.query(tasks, { contact_info_facebook: 'Yes' }, account_list).to_a).to eq [task_one]
      end
    end
  end
end
