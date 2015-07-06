require 'spec_helper'

describe ContactDuplicatesFinder do
  let(:account_list) { create(:account_list) }
  let(:user) { create(:person) }
  let(:dups_finder) { ContactDuplicatesFinder.new(account_list, user) }

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
  ]

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
  ]

  def create_records_for_name_list
    create(:nickname, name: 'andrew', nickname: 'andy', suggest_duplicates: true)
    create(:name_male_ratio, name: 'jonathan', male_ratio: 0.996)
    create(:name_male_ratio, name: 'florence', male_ratio: 0.003)
  end

  describe '#dup_people_sets ' do
    def dup_people
      contacts, people = dups_finder.dup_contacts_then_people
      expect(contacts).to be_empty
      people
    end

    it 'does not find duplicates with no shared contact' do
      expect(dup_people).to be_empty
    end

    describe 'finding duplicates with a shared contact' do
      before do
        contact1.people << person2
        contact1.people << person1
      end

      def expect_people_set
        dups = dup_people
        expect(dups.size).to eq(1)
        dup = dups.first
        expect([dup.person, dup.dup_person]).to include(person1)
        expect([dup.person, dup.dup_person]).to include(person2)
        expect(dup.shared_contact).to eq(contact1)
      end

      it 'finds duplicates by same name' do
        expect_people_set
      end

      it 'does not find duplicates if no matching info' do
        person1.update_column(:first_name, 'Notjohn')
        expect(dup_people).to be_empty
      end

      it 'does not find duplicates if people marked as not duplicated with each other' do
        person1.update_column(:not_duplicated_with, person2.id.to_s)
        expect(dup_people).to be_empty
      end

      it 'finds duplicates by nickname' do
        nickname
        person1.update_column(:first_name, 'johnny')

        dups = dup_people
        expect(dups.size).to eq(1)
        dup = dups.first

        # Expect the person with the nickname to be dup.person, while the full name to be dup_person
        # That will cause the default merged person to have the nickname.
        expect(dup.person).to eq(person1)
        expect(dup.dup_person).to eq(person2)

        expect(dup.shared_contact).to eq(contact1)
      end

      it 'finds duplicates but uses common conventions to guess which the user would pick as a winner' do
        # Set the contact info to verify that the contact info matching doesn't mess with the ordering below
        person1.phone = '123-456-7890'
        person1.email = 'same@example.com'
        person1.save
        person2.phone = '(123) 456-7890'
        person2.email = 'Same@Example.com'
        person2.save

        # Prefer nicknames, matched middle names, two letter initials (common nickname), two word names, and
        # trying to preserve capitalization. Don't preference names that are just an initial or include an initial and a name.
        order_preserving_matches = [
          [{ first_name: 'johnny' }, { first_name: 'John' }],
          [{ first_name: 'Jo' }, { first_name: 'jo' }],
          [{ first_name: 'John' }, { first_name: 'George', middle_name: 'J' }],
          [{ first_name: 'John' }, { first_name: 'J', middle_name: nil }],
          [{ first_name: 'Mary Beth' }, { first_name: 'Mary' }],
          [{ first_name: 'AnnMarie' }, { first_name: 'Annmarie' }],
          [{ first_name: 'Andy' }, { first_name: 'Grable A' }],
          [{ first_name: 'JW' }, { first_name: 'John' }],
          [{ first_name: 'C. S.' }, { first_name: 'Clive' }],
          [{ first_name: 'A.J.' }, { first_name: 'Andrew' }],
          [{ first_name: 'John' }, { first_name: 'john' }],
          [{ first_name: 'John' }, { first_name: 'John.' }],
          [{ first_name: 'David' }, { first_name: 'J David' }],
          [{ first_name: 'David' }, { first_name: 'J. David' }],
          [{ first_name: 'Andy' }, { first_name: 'A A' }],
          [{ first_name: 'Somebody', last_name: 'Doe' }, { first_name: 'Match by contact info', last_name: 'Notdoe' }],
          [{ first_name: 'Somebody', last_name: 'doe' }, { first_name: 'Match by contact info', last_name: 'Notdoe' }],
          [{ first_name: 'Somebody', last_name: 'Notdoe' }, { first_name: 'Match by contact info', last_name: nil }]
        ]
        nickname

        order_preserving_matches.each do |first_fields, second_fields|
          person1.update_columns(first_fields)
          person2.update_columns(second_fields)
          dups = dup_people
          expect(dups.size).to eq(1)
          expect(dups.first.person).to eq(person1)
          expect(dups.first.dup_person).to eq(person2)
          expect(dups.first.shared_contact).to eq(contact1)

          # Reverse the order of person 1 and 2 and make sure it still works
          person2.update_columns(first_fields)
          person1.update_columns(second_fields)
          dups = dup_people
          expect(dups.size).to eq(1)
          expect(dups.first.person).to eq(person2)
          expect(dups.first.dup_person).to eq(person1)
          expect(dups.first.shared_contact).to eq(contact1)
        end
      end

      it 'finds duplicates by email' do
        person1.update_column(:first_name, 'Notjohn')
        person1.email = 'same@example.com'
        person1.save
        person2.email = 'Same@Example.com'
        person2.save

        expect_people_set
      end

      it 'finds duplicates by phone' do
        person1.update_column(:first_name, 'Notjohn')
        person1.phone = '123-456-7890'
        person1.save
        person2.phone = '(123) 456-7890'
        person2.save

        expect_people_set
      end

      it 'does not report duplicates by phone or email if the people have different genders' do
        person1.update_column(:first_name, 'Notjohn')
        person1.update_column(:gender, 'female')
        person2.update_column(:gender, 'male')

        person1.phone = '123-456-7890'
        person1.email = 'same@example.com'
        person1.save
        person2.phone = '(123) 456-7890'
        person2.email = 'Same@Example.com'
        person2.save

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates by phone or email if the people have different genders and one has a gender name record' do
        create(:name_male_ratio, name: 'john', male_ratio: 0.996)

        person1.update_column(:first_name, 'Jane')
        person1.update_column(:gender, 'female')
        person2.update_column(:gender, 'male')

        person1.phone = '123-456-7890'
        person1.email = 'same@example.com'
        person1.save
        person2.phone = '(123) 456-7890'
        person2.email = 'Same@Example.com'
        person2.save

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates by phone or email if the people name components are strongly different genders' do
        create(:name_male_ratio, name: 'david', male_ratio: 0.996)
        create(:name_male_ratio, name: 'lara', male_ratio: 0.001)

        person1.first_name = 'J David'
        person1.phone = '123-456-7890'
        person1.email = 'same@example.com'
        person1.gender = 'male'
        person1.save

        person2.first_name = 'Lara'

        person2.phone = '(123) 456-7890'
        person2.gender = 'male' # sometimes the gender field data is wrong, simulate that
        person2.email = 'Same@Example.com'
        person2.save

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates by name if middle name initials match but name components strongly different genders' do
        create(:name_male_ratio, name: 'david', male_ratio: 0.996)
        create(:name_male_ratio, name: 'lara', male_ratio: 0.001)

        person1.first_name = 'J David'
        person1.middle_name = 'M'
        person1.gender = 'male'
        person1.save

        person2.first_name = 'Lara'
        person2.middle_name = 'M'
        person2.gender = 'male' # sometimes the gender field data is wrong, simulate that
        person2.save

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates by name if middle name initials match but different genders' do
        person1.first_name = 'J David'
        person1.middle_name = 'M'
        person1.gender = 'male'
        person1.save

        person2.first_name = 'Lara'
        person2.middle_name = 'M'
        person2.gender = 'female'
        person2.save

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates by name if legal first name matches but name genders are off' do
        create(:name_male_ratio, name: 'thomas', male_ratio: 0.996)
        create(:name_male_ratio, name: 'laura', male_ratio: 0.003)

        # This can happen in the data that the legal first name gets set to the spouse name, so we need to check genders.
        person1.first_name = 'Thomas'
        person1.legal_first_name = 'Laura'
        person1.gender = 'female'
        person1.save

        person2.first_name = 'Laura'
        person2.gender = 'female'
        person2.save

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates by middle name only' do
        person1.update_columns(first_name: 'Notjohn', middle_name: 'George')
        person2.update_column(:middle_name, 'George')

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates if "first1 and first2" are in the contact name' do
        contact1.update_column(:name, 'Doe, John and Jane')

        person1.first_name = 'John'
        person1.phone = '123-456-7890'
        person1.email = 'same@example.com'
        person1.save

        person2.first_name = 'Jane'
        person2.phone = '(123) 456-7890'
        person2.email = 'Same@Example.com'
        person2.save

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates if "first1 and first2" are in the contact name with extra names' do
        contact1.update_column(:name, 'Doe, John Henry and Jane Mae')

        person1.first_name = 'John'
        person1.phone = '123-456-7890'
        person1.email = 'same@example.com'
        person1.save

        person2.first_name = 'Jane'
        person2.phone = '(123) 456-7890'
        person2.email = 'Same@Example.com'
        person2.save

        expect(dup_people).to be_empty
      end

      it 'does not report duplicates if middle name matches first name but name genders are off' do
        create(:name_male_ratio, name: 'david', male_ratio: 0.996)
        create(:name_male_ratio, name: 'lara', male_ratio: 0.001)

        person1.first_name = 'David'
        person1.middle_name = 'Lara'
        person1.save

        person2.first_name = 'Lara'
        person2.middle_name = 'M'
        person2.save

        expect(dup_people).to be_empty
      end

      def expect_matching_people(first_names)
        person1.update_column(:first_name, first_names[0])
        person2.update_column(:first_name, first_names[1])
        expect_people_set
      end

      def expect_non_matching_people(first_names)
        person1.update_column(:first_name, first_names[0])
        person2.update_column(:first_name, first_names[1])
        expect(dup_people).to be_empty
      end

      it 'finds people by matching initials and middle names in the first name field' do
        create_records_for_name_list
        MATCHING_FIRST_NAMES.each(&method(:expect_matching_people))
        NON_MATCHING_FIRST_NAMES.each(&method(:expect_non_matching_people))
      end

      it 'finds duplicate contacts by middle_name field' do
        nickname
        person1.update_columns(first_name: 'Notjohn', middle_name: 'Johnny')
        expect_people_set
      end

      it 'finds duplicate contacts by middle_name field with name expansion' do
        nickname
        person1.update_columns(first_name: 'Notjohn', middle_name: 'JT')
        expect_people_set
      end

      it 'finds duplicate contacts by legal_first_name field' do
        person1.update_columns(first_name: 'Notjohn', legal_first_name: 'John')
        expect_people_set
      end

      it 'does not match people in an anonymous contact' do
        expect_people_set
        contact1.update_column(:name, 'ANONYMOUS')
        expect(dup_people).to be_empty
      end

      it 'does not match people by name if first name / last name like "Friend of the ministry"' do
        person1.update_columns(first_name: 'Friend', last_name: 'of the Ministry')
        person2.update_columns(first_name: 'Friend', last_name: 'of the Ministry')
        expect(dup_people).to be_empty
      end

      it 'matches people by contact info if name like "Friend of the ministry"' do
        person1.update_columns(first_name: 'Friend', last_name: 'of the Ministry')
        person2.update_columns(first_name: 'Friend', last_name: 'of the Ministry')
        person1.email = 'same@example.com'
        person2.email = 'same@example.com'
        expect_people_set
      end

      it 'does not match people by contact info if name like "Unknown"' do
        person1.update_columns(first_name: 'Unknown')
        person2.update_columns(first_name: 'unknown')
        person1.email = 'same@example.com'
        person2.email = 'same@example.com'
        expect(dup_people).to be_empty
      end
    end
  end

  describe '#dup_contact_sets' do
    before do
      contact1.people << person1
      contact2.people << person2
    end

    def dup_contacts
      dups_finder.dup_contacts_then_people.first
    end

    def expect_contact_set
      dups = dup_contacts
      expect(dups.size).to eq(1)
      dup = dups.first
      expect(dup.size).to eq(2)
      expect(dup).to include(contact1)
      expect(dup).to include(contact2)
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
      person1.phone = '123-456-7890'
      person1.save
      person2.phone = '(123) 456-7890'
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
