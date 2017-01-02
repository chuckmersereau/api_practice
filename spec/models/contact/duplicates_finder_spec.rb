require 'spec_helper'

describe Contact::DuplicatesFinder do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:dups_finder) { Contact::DuplicatesFinder.new(account_list) }

  let(:person1) { create(:person, first_name: 'john', last_name: 'doe') }
  let(:person2) { create(:person, first_name: 'John', last_name: 'Doe') }
  let(:contact1) { create(:contact, name: 'Doe, John 1', account_list: account_list) }
  let(:contact2) { create(:contact, name: 'Doe, John 2', account_list: account_list) }

  let(:nickname) { create(:nickname, name: 'john', nickname: 'johnny', suggest_duplicates: true) }

  MATCHING_FIRST_NAMES = [
    ['Grable A', 'Andy'],
    ['Grable A', 'G Andrew'],
    ['G Andrew', 'Andy'],
    ['G Andrew', 'G Andy'],
    %w(A Andy),
    %w(A Andrew),
    %w(Andy Andrew),
    %w(GA Andrew),
    %w(GA Andy),
    ['GA', 'Grable A'],
    ['G.A.', 'Grable A'],
    ['G.A.', 'G A'],
    ['G.A.', 'Andy'],
    ['G.A.', 'Grable'],
    ['G A.', 'Andy'],
    ['G A.', 'Grable'],
    ['G A.', 'Andy'],
    ['G A.', 'Grable'],
    ['A G', 'Grable'],
    ['A G', 'Andrew'],
    ['Grable Andy', 'Andrew'],
    ['Grable Andrew', 'Andy'],
    ['Grable Andy', 'G Andrew'],
    ['Grable Andrew', 'G Andy'],
    %w(CC Charlie),
    %w(C Charlie),
    ['Hoo-Tee', 'Hoo Tee'],
    ['HooTee', 'Hoo Tee'],
    ['Hootee', 'Hoo Tee'],
    ['Mary Beth', 'Marybeth'],
    ['JW', 'john wilson']
  ].freeze

  NON_MATCHING_FIRST_NAMES = [
    %w(G Andy),
    %w(Grable Andy),
    ['Grable B', 'Andy'],
    ['G B', 'Andy'],
    %w(Andrew Andrea),
    ['CCC NEHQ', 'Charlie'],
    ['Dad US', 'Scott'],
    ['Jonathan F', 'Florence'],
    %w(Unknown Unknown)
  ].freeze

  def create_records_for_name_list
    create(:nickname, name: 'andrew', nickname: 'andy', suggest_duplicates: true)
    create(:name_male_ratio, name: 'jonathan', male_ratio: 0.996)
    create(:name_male_ratio, name: 'florence', male_ratio: 0.003)
  end

  describe '#find' do
    before do
      contact1.people << person1
      contact2.people << person2
    end

    def dup_contacts
      dups_finder.find
    end

    def expect_contact_set
      dups = dup_contacts
      expect(dups.size).to eq(1)
      dup = dups.first
      expect(dup.contacts.size).to eq(2)
      expect(dup.contacts).to include(contact1)
      expect(dup.contacts).to include(contact2)
    end

    it 'finds duplicate contacts given for people with the same name' do
      expect_contact_set
    end

    it 'does not find duplicates if contacts have no matching info' do
      person1.update_column(:first_name, 'Notjohn')
      expect(dup_contacts).to be_empty
    end

    it 'does not find duplicates if a contact is marked as not duplicated with the other' do
      contact1.update_column(:not_duplicated_with, contact2.id)

      dups = dup_contacts
      expect(dups.size).to eq(0)
    end

    it 'finds duplicates by people with matching nickname' do
      nickname # create the nickname in the let expression above
      person1.update_column(:first_name, 'Johnny')
      expect_contact_set
    end

    it 'finds duplicates by people with matching email' do
      person1.update_column(:first_name, 'Notjohn')
      person1.email = 'same@example.com'
      person1.save
      person2.email = 'Same@Example.com'
      person2.save

      expect_contact_set
    end

    it 'finds duplicates by people with matching phone' do
      person1.update_column(:first_name, 'Notjohn')
      person1.phone = '213-456-7890'
      person1.save
      person2.phone = '(213) 456-7890'
      person2.save

      expect_contact_set
    end

    describe 'match by address' do
      before do
        stub_request(:get, %r{https://api\.smartystreets\.com/street-address/.*}).to_return(body: '[]')
        person1.update_column(:first_name, 'Notjohn')
      end

      it 'finds duplicates by matching primary address' do
        contact1.addresses_attributes = [{ street: '1 Road', primary_mailing_address: true, master_address_id: 1 }]
        contact1.save
        contact2.addresses_attributes = [{ street: '1 Rd', primary_mailing_address: true, master_address_id: 1 }]
        contact2.save
        expect_contact_set
      end

      it 'does not find duplicates by matching primary address if insufficient address' do
        contact1.addresses_attributes = [{ street: 'Insufficient Address', primary_mailing_address: true, master_address_id: 1 }]
        contact1.save
        contact2.addresses_attributes = [{ street: '1 Rd', primary_mailing_address: true, master_address_id: 1 }]
        contact2.save
        expect(dup_contacts).to be_empty
      end

      it 'does not find duplicates by matching primary address if street is empty string' do
        contact1.addresses << Address.new(street: '', primary_mailing_address: true, master_address_id: 1)
        contact2.addresses << Address.new(street: '', primary_mailing_address: true, master_address_id: 1)
        expect(dup_contacts).to be_empty
      end

      it 'does not find duplicates by matching primary address if street is nil' do
        contact1.addresses << Address.new(street: nil, primary_mailing_address: true, master_address_id: 1)
        contact2.addresses << Address.new(street: nil, primary_mailing_address: true, master_address_id: 1)
        expect(dup_contacts).to be_empty
      end

      it 'does not find duplicats by matching primary address if either address is deleted' do
        a1 = Address.new(street: '1', primary_mailing_address: true, master_address_id: 1)
        a2 = Address.new(street: '1', primary_mailing_address: true, master_address_id: 1)
        contact1.addresses << a1
        contact2.addresses << a2
        expect_contact_set
        a1.update_column(:deleted, true)
        expect(dup_contacts).to be_empty
        a1.update_column(:deleted, false)
        a2.update_column(:deleted, true)
        expect(dup_contacts).to be_empty
      end
    end

    it 'does not find the same contact as a duplicate if the persons name would match itself' do
      person1.update_column(:first_name, 'John B')
      person2.update_column(:first_name, 'Brian')
      contact1.people << person2
      contact2.destroy

      expect(dup_contacts).to be_empty
    end

    def expect_matching_contacts(first_names)
      person1.update_column(:first_name, first_names[0])
      person2.update_column(:first_name, first_names[1])
      expect_contact_set
    end

    def expect_non_matching_contacts(first_names)
      person1.update_column(:first_name, first_names[0])
      person2.update_column(:first_name, first_names[1])
      expect(dup_contacts).to be_empty
    end

    it 'finds contacts by matching initials and middle names in the first name field' do
      create_records_for_name_list
      MATCHING_FIRST_NAMES.each(&method(:expect_matching_contacts))
      NON_MATCHING_FIRST_NAMES.each(&method(:expect_non_matching_contacts))
    end

    it 'does not find duplicate contacts by middle_name field (too aggressive for contact match)' do
      nickname
      person1.update_columns(first_name: 'Notjohn', middle_name: 'Johnny')
      expect(dup_contacts).to be_empty
    end

    it 'does not match anonymous contacts together' do
      expect_contact_set
      contact1.update_column(:name, 'totally anonymous')
      expect(dup_contacts).to be_empty
    end

    it 'does not match contacts by person name if like "Friend of the ministry"' do
      person1.update_columns(first_name: 'Friends of THE', last_name: 'Ministry')
      person2.update_columns(first_name: 'friends of the', last_name: 'ministry')
      expect(dup_contacts).to be_empty
    end

    it 'does not match contacts by contact info if person name like "Friend of the ministry"' do
      person1.update_columns(first_name: 'Friend', last_name: 'of the Ministry')
      person2.update_columns(first_name: 'Friend', last_name: 'of the Ministry')
      person1.phone = '123-456-7890'
      person2.phone = '(123) 456-7890'
      expect(dup_contacts).to be_empty
    end

    it 'does not match contacts by people contact info if name like "Unknown"' do
      person1.update_columns(first_name: 'Unknown')
      person2.update_columns(first_name: 'unknown')
      person1.email = 'same@example.com'
      person2.email = 'same@example.com'
      expect(dup_contacts).to be_empty
    end
  end
end
