require 'rails_helper'

RSpec.describe Tools::Analytics do
  let(:account_list) { create(:account_list) }

  let!(:contact_one) { create(:contact, account_list: account_list, status_valid: false) }
  let!(:contact_two) { create(:contact, account_list: account_list) }
  let!(:contact_three) { create(:contact, account_list: account_list) }

  let!(:address) { create(:address, addressable: contact_one, source: 'Random Source') }
  let!(:second_address) { create(:address, addressable: contact_one) }

  let(:person) { create(:person, contacts: [contact_two]) }

  let!(:email_address)        { create(:email_address, person: person, source: 'Random Source') }
  let!(:second_email_address) { create(:email_address, person: person) }

  let!(:phone_number)         { create(:phone_number, person: person, source: 'Random Source') }
  let!(:second_phone_number)  { create(:phone_number, person: person) }

  subject { described_class.new(account_lists: [account_list]) }

  describe '#counts_by_type' do
    let(:counts_by_type) { subject.counts_by_type }
    let(:first_counts_array) { counts_by_type.first[:counts] }

    let(:contact_duplicates) { double }
    let(:people_duplicates) { double }

    before do
      allow_any_instance_of(Contact::DuplicatePairsFinder).to receive(:find_and_save)
      allow(DuplicateRecordPair).to receive_message_chain(:type, :where, :count).and_return(3)

      allow_any_instance_of(Person::DuplicatesFinder).to receive(:find).and_return(people_duplicates)
      allow(people_duplicates).to receive(:count).and_return(2)
    end

    it 'returns the account_list uuid for each account_list' do
      expect(counts_by_type.first[:id]).to eq(account_list.uuid)
    end

    it 'returns the list of counts by type for each account list' do
      expect_type_and_count(first_counts_array.first, 'fix-commitment-info', 1)
      expect_type_and_count(first_counts_array.second, 'fix-phone-numbers', 1)
      expect_type_and_count(first_counts_array.third, 'fix-email-addresses', 1)
      expect_type_and_count(first_counts_array.fourth, 'fix-addresses', 1)
      expect_type_and_count(first_counts_array.fifth, 'duplicate-contacts', 3)
      expect_type_and_count(first_counts_array.last, 'duplicate-people', 2)
    end

    def expect_type_and_count(count_object, type, count)
      expect(count_object[:type]).to eq(type)
      expect(count_object[:count]).to eq(count)
    end
  end
end
