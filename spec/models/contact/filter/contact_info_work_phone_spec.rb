require 'spec_helper'

RSpec.describe Contact::Filter::ContactInfoWorkPhone do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }

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

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: false,
                                                              name: :contact_info_work_phone,
                                                              options: [{ name: '-- Any --', id: '', placeholder: 'None' }, { name: 'Yes', id: 'Yes' }, { name: 'No', id: 'No' }],
                                                              parent: 'Contact Information',
                                                              title: 'Work Phone',
                                                              type: 'radio',
                                                              default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { contact_info_work_phone: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { contact_info_work_phone: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { contact_info_work_phone: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by no work phone' do
      it 'returns only contacts that have no work phone' do
        expect(described_class.query(contacts, { contact_info_work_phone: 'No' }, nil).to_a).to match_array [contact_two, contact_three, contact_four]
      end
    end

    context 'filter by work phone' do
      it 'returns only contacts that have a work phone' do
        expect(described_class.query(contacts, { contact_info_work_phone: 'Yes' }, nil).to_a).to match_array [contact_one]
      end
    end
  end
end
