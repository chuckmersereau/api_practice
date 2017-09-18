require 'rails_helper'

RSpec.describe Tools::Analytics do
  let!(:account_list) { create(:account_list) }

  let!(:contact_one) { create(:contact, account_list: account_list, status_valid: false, send_newsletter: 'None') }
  let!(:contact_two) { create(:contact, account_list: account_list, send_newsletter: nil, status: 'Partner - Pray') }
  let!(:contact_three) { create(:contact, account_list: account_list, send_newsletter: 'Physical') }

  let!(:address) { create(:address, addressable: contact_one) }
  let!(:second_address) { create(:address, addressable: contact_one, source: 'Random Source') }

  let!(:person) { create(:person, contacts: [contact_two]) }

  let!(:email_address)        { create(:email_address, person: person) }
  let!(:second_email_address) { create(:email_address, person: person, source: 'Random Source') }

  let!(:phone_number)         { create(:phone_number, person: person) }
  let!(:second_phone_number)  { create(:phone_number, person: person, source: 'Random Source') }

  # Inactive contacts should be excluded.
  let!(:contact_inactive) { create(:contact, account_list: account_list, status_valid: false, status: Contact::INACTIVE_STATUSES.first) }

  let!(:address_inactive) { create(:address, addressable: contact_inactive, source: 'Random Source', valid_values: false) }

  subject { described_class.new(account_lists: [account_list]) }

  describe '#counts_by_type' do
    let(:counts_by_type) { subject.counts_by_type }
    let(:first_counts_array) { counts_by_type.first[:counts] }

    let(:contact_duplicates) { double }
    let(:people_duplicates) { double }

    before do
      allow_any_instance_of(Contact::DuplicatePairsFinder).to receive(:find_and_save)
      dup_contact_pairs_double = double
      allow(dup_contact_pairs_double).to receive_message_chain(:where, :count).and_return(3)
      allow(DuplicateRecordPair).to receive(:type).with('Contact').and_return(dup_contact_pairs_double)

      allow_any_instance_of(Person::DuplicatePairsFinder).to receive(:find_and_save)
      dup_person_pairs_double = double
      allow(dup_person_pairs_double).to receive_message_chain(:where, :count).and_return(2)
      allow(DuplicateRecordPair).to receive(:type).with('Person').and_return(dup_person_pairs_double)
    end

    it 'returns the account_list uuid for each account_list' do
      expect(counts_by_type.first[:id]).to eq(account_list.uuid)
    end

    it 'returns the list of counts by type for each account list' do
      expect_type_and_count(first_counts_array[0], 'fix-commitment-info', 1)
      expect_type_and_count(first_counts_array[1], 'fix-phone-numbers', 1)
      expect_type_and_count(first_counts_array[2], 'fix-email-addresses', 1)
      expect_type_and_count(first_counts_array[3], 'fix-addresses', 1)
      expect_type_and_count(first_counts_array[4], 'fix-send-newsletter', 1)
      expect_type_and_count(first_counts_array[5], 'duplicate-contacts', 3)
      expect_type_and_count(first_counts_array[6], 'duplicate-people', 2)
    end

    def expect_type_and_count(count_object, type, count)
      expect(count_object[:type]).to eq(type)
      expect(count_object[:count]).to eq(count)
    end
  end
end
