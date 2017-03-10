require 'rails_helper'

RSpec.describe Contact::Filter::Appeal do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:appeal_1) { create(:appeal, account_list_id: account_list.id) }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, no_appeals: true) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, no_appeals: true) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, no_appeals: nil) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, no_appeals: false) }

  before do
    AppealContact.create! contact: contact_one, appeal: appeal_1
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :appeal,
                                                                options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                                                                          { name: '-- Do not ask --', id: 'no_appeals' },
                                                                          { name: appeal_1.name, id: appeal_1.uuid }],
                                                                parent: nil,
                                                                title: 'Appeal',
                                                                type: 'multiselect',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { appeal: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { appeal: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { appeal: [''] }, nil)).to eq(nil)
      end
    end

    context 'filter with no appeals' do
      it 'returns only contacts with no_appeals set to true' do
        expect(described_class.query(contacts, { appeal: 'no_appeals' }, nil).to_a).to eq [contact_one, contact_two]
      end
      it 'returns only contacts with no_appeals set to true and who are part of the appeal' do
        expect(described_class.query(contacts, { appeal: "#{appeal_1.uuid}, no_appeals" }, nil).to_a).to eq [contact_one]
      end
    end

    context 'filter by appeals' do
      it 'returns only contacts associated to the selected appeal' do
        expect(described_class.query(contacts, { appeal: appeal_1.uuid }, nil).to_a).to eq [contact_one]
      end
    end
  end
end
