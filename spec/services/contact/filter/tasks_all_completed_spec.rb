require 'rails_helper'

RSpec.describe Contact::Filter::TasksAllCompleted do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }

  before do
    contact_one.tasks << create(:task, completed: false)
    contact_one.tasks << create(:task, completed: true)

    contact_two.tasks << create(:task, completed: true)
    contact_two.tasks << create(:task, completed: true)

    contact_three.tasks << create(:task, completed: false)
    contact_three.tasks << create(:task, completed: false)

    contact_four.tasks.delete_all
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(name: :tasks_all_completed,
                                                                parent: 'Tasks',
                                                                title: 'No Incomplete Tasks',
                                                                type: 'single_checkbox',
                                                                default_selection: false)
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { tasks_all_completed: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { tasks_all_completed: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { tasks_all_completed: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by tasks_all_completed true' do
      it 'returns only contacts that have no incomplete tasks' do
        expect(described_class.query(contacts, { tasks_all_completed: 'true' }, nil).to_a).to match_array [contact_two, contact_four]
        contact_one.tasks.update_all(completed: true)
        expect(described_class.query(contacts, { tasks_all_completed: 'true' }, nil).to_a).to match_array [contact_one, contact_two, contact_four]
        contact_four.tasks << create(:task, completed: false)
        expect(described_class.query(contacts, { tasks_all_completed: 'true' }, nil).to_a).to match_array [contact_one, contact_two]
      end
    end

    context 'filter by tasks_all_completed false' do
      it 'does not filter' do
        expect(described_class.query(contacts, { tasks_all_completed: 'false' }, nil).to_a).to match_array [contact_one, contact_two, contact_three, contact_four]
        contact_five = create(:contact, account_list_id: account_list.id)
        expect(described_class.query(contacts, { tasks_all_completed: 'false' }, nil).to_a).to match_array [contact_one, contact_two, contact_three, contact_four, contact_five]
      end
    end
  end
end
