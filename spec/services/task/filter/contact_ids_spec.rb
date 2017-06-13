require 'rails_helper'

RSpec.describe Task::Filter::ContactIds do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list: account_list) }
  let!(:contact_two)   { create(:contact, account_list: account_list) }
  let!(:task_one)   { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two)   { create(:task, account_list: account_list, contacts: [contact_two]) }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(default_selection: '',
                                                                multiple: true,
                                                                name: :contact_ids,
                                                                options: [{ name: '-- Any --', id: '', placeholder: 'None' }] +
                                                                           account_list.contacts.order('name ASC').collect do |contact|
                                                                             { name: contact.to_s, id: contact.uuid, account_list_id: account_list.uuid }
                                                                           end,
                                                                parent: nil,
                                                                priority: 1,
                                                                title: 'Contacts',
                                                                type: 'multiselect')
    end
  end

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, nil)).to eq(nil)
        expect(described_class.query(tasks, { contact_ids: {} }, nil)).to eq(nil)
        expect(described_class.query(tasks, { contact_ids: [] }, nil)).to eq(nil)
        expect(described_class.query(tasks, { contact_ids: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by activity_type' do
      it 'filters single contact' do
        expect(described_class.query(tasks, { contact_ids: contact_one.uuid }, nil).to_a).to include(task_one)
      end
      it 'filters multiple contacts' do
        expect(described_class.query(tasks, { contact_ids: "#{contact_one.uuid}, #{contact_two.uuid}" }, nil).to_a).to include(task_two)
      end
    end
  end
end
