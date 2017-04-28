require 'rails_helper'

RSpec.describe Contact::Filter::RelatedTaskAction do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let(:task_one) { create(:task, account_list: account_list, activity_type: 'Email') }
  let(:task_two) { create(:task, account_list: account_list, activity_type: 'Call') }

  let!(:contact_one)   { create(:contact, status: 'Partner - Financial', account_list: account_list, tasks: [task_one]) }
  let!(:contact_two)   { create(:contact, status: 'Partner - Financial', account_list: account_list, tasks: [task_one]) }
  let!(:contact_three) { create(:contact, status: 'Partner - Financial', account_list: account_list, tasks: [task_two]) }
  let!(:contact_four) { create(:contact, status: 'Partner - Financial', account_list: account_list) }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :related_task_action,
                                                                options: [
                                                                  { name: '-- Any --', id: '', placeholder: 'None' },
                                                                  { name: '-- None --', id: 'none' },
                                                                  { name: 'Call', id: 'Call' },
                                                                  { name: 'Email', id: 'Email' }
                                                                ],
                                                                parent: 'Tasks',
                                                                title: 'Action',
                                                                type: 'multiselect',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { related_task_action: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { related_task_action: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { related_task_action: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by Related Task Action Type' do
      it 'returns only contacts that have no related tasks when null is passed' do
        expect(described_class.query(contacts, { related_task_action: 'null' }, nil).to_a).to match_array [contact_four]
      end
      it 'returns only contacts with tasks of the specified activity type when specified' do
        expect(described_class.query(contacts, { related_task_action: 'Email' }, nil).to_a).to match_array [contact_one, contact_two]
        expect(described_class.query(contacts, { related_task_action: 'Call' }, nil).to_a).to match_array [contact_three]
      end
    end
  end
end
