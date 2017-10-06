require 'rails_helper'

describe Person::DuplicatePairsFinder do
  let!(:account_list) { create(:user_with_account).account_lists.first }

  let!(:contact) { create(:contact, account_list: account_list) }

  let!(:unique_person_one) do
    create(:person, first_name: 'This person should have no duplicates', last_name: 'No Duplicates').tap do |person|
      person.email_addresses << create(:email_address, email: '121349087191873491@asdflkhasdfghasdlfkhjasdh.com')
      person.phone_numbers << create(:phone_number, number: '21123864192836465189346712893467')
      contact.people << person
    end
  end

  let!(:unique_person_two) do
    create(:person, first_name: 'This is another person that is a totally unique individual', last_name: 'Totally Unique').tap do |person|
      person.email_addresses << create(:email_address, email: 'adasdflhasdhgadfklsdjaf@1234123461238965348975623.com')
      person.phone_numbers << create(:phone_number, number: '1623487916235819367419283467')
      contact.people << person
    end
  end

  def build_finder
    Person::DuplicatePairsFinder.new(account_list)
  end

  it 'deletes pairs with missing records' do
    valid_pair = DuplicateRecordPair.create!(
      account_list: account_list,
      reason: 'Test',
      record_one: unique_person_one,
      record_two: unique_person_two
    )
    person = create(:person, first_name: 'John', last_name: 'Doe').tap { |created_person| contact.people << created_person }

    pair_missing_record_one = DuplicateRecordPair.new(
      account_list: account_list,
      reason: 'Test',
      record_one_id: person.id + 1,
      record_one_type: 'Person',
      record_two_id: person.id,
      record_two_type: 'Person'
    )
    pair_missing_record_one.save(validate: false)

    pair_missing_record_two = DuplicateRecordPair.new(
      account_list: account_list,
      reason: 'Test',
      record_one_id: person.id,
      record_one_type: 'Person',
      record_two_id: person.id + 2,
      record_two_type: 'Person'
    )
    pair_missing_record_two.save(validate: false)

    expect { build_finder.find_and_save }.to change { DuplicateRecordPair.count }.by(-2)

    expect(DuplicateRecordPair.exists?(pair_missing_record_one.id)).to eq(false)
    expect(DuplicateRecordPair.exists?(pair_missing_record_two.id)).to eq(false)
    expect(DuplicateRecordPair.exists?(valid_pair.id)).to eq(true)
  end

  it 'does not find duplicates from a different account list' do
    person = create(:person, first_name: 'John', last_name: 'Doe')
    create(:contact, account_list: account_list).people << person
    create(:contact).people << person

    expect do
      expect(build_finder.find_and_save).to eq([])
    end.to_not change { DuplicateRecordPair.count }.from(0)
  end

  it 'does not find duplicates from a different contact in the same account list' do
    person = create(:person, first_name: 'John', last_name: 'Doe')
    create(:contact, account_list: account_list).people << person
    create(:contact, account_list: account_list).people << person

    expect do
      expect(build_finder.find_and_save).to eq([])
    end.to_not change { DuplicateRecordPair.count }.from(0)
  end

  context 'people with the same first and last names' do
    let!(:person_one) { create(:person, first_name: 'John', last_name: 'Doe').tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'John', last_name: 'Doe').tap { |person| contact.people << person } }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar names', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same first and last names but different formatting' do
    let!(:person_one) { create(:person, first_name: ' john, ', last_name: 'DOE   ').tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: "\nJohn\r", last_name: "Doe'").tap { |person| contact.people << person } }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar names', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same first name but missing last names' do
    let!(:person_one) { create(:person, first_name: 'John', last_name: 'Doe').tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'John', last_name: nil).tap { |person| contact.people << person } }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar names', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same first name but different last names' do
    let!(:person_one) { create(:person, first_name: 'John', last_name: 'Doe').tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'John', last_name: 'Jones').tap { |person| contact.people << person } }

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'people with the same email addresses and same gender' do
    let!(:person_one) { create(:person, first_name: 'John', last_name: 'Doe', gender: 'male').tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'Bob', last_name: 'Jones', gender: 'male').tap { |person| contact.people << person } }
    let!(:email_address_one) { create(:email_address, email: '  duplicate@email.com  ').tap { |email_address| person_one.email_addresses << email_address } }
    let!(:email_address_two) { create(:email_address, email: 'Duplicate@Email.COM').tap { |email_address| person_two.email_addresses << email_address } }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar email addresses', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same email addresses and different gender' do
    let!(:person_one) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female').tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'Bob', last_name: 'Jones', gender: 'male').tap { |person| contact.people << person } }
    let!(:email_address_one) { create(:email_address, email: '  duplicate@email.com  ').tap { |email_address| person_one.email_addresses << email_address } }
    let!(:email_address_two) { create(:email_address, email: 'Duplicate@Email.COM').tap { |email_address| person_two.email_addresses << email_address } }

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'people with the same email addresses and no gender' do
    let!(:person_one) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: nil).tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'Bob', last_name: 'Jones', gender: nil).tap { |person| contact.people << person } }
    let!(:email_address_one) { create(:email_address, email: '  duplicate@email.com  ').tap { |email_address| person_one.email_addresses << email_address } }
    let!(:email_address_two) { create(:email_address, email: 'Duplicate@Email.COM').tap { |email_address| person_two.email_addresses << email_address } }

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'people with the same phone numbers and same gender' do
    let!(:person_one) { create(:person, first_name: 'John', last_name: 'Doe', gender: 'male').tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'Bob', last_name: 'Jones', gender: 'male').tap { |person| contact.people << person } }
    let!(:phone_number_one) { create(:phone_number, number: '1.234.567.890!  ').tap { |phone_number| person_one.phone_numbers << phone_number } }
    let!(:phone_number_two) { create(:phone_number, number: '+1234567890').tap { |phone_number| person_two.phone_numbers << phone_number } }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar phone numbers', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same phone numbers and different gender' do
    let!(:person_one) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female').tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'Bob', last_name: 'Jones', gender: 'male').tap { |person| contact.people << person } }
    let!(:phone_number_one) { create(:phone_number, number: '1.234.567.890!  ').tap { |phone_number| person_one.phone_numbers << phone_number } }
    let!(:phone_number_two) { create(:phone_number, number: '+1234567890').tap { |phone_number| person_two.phone_numbers << phone_number } }

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'people with the same phone numbers and no gender' do
    let!(:person_one) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: nil).tap { |person| contact.people << person } }
    let!(:person_two) { create(:person, first_name: 'Bob', last_name: 'Jones', gender: nil).tap { |person| contact.people << person } }
    let!(:phone_number_one) { create(:phone_number, number: '1.234.567.890!  ').tap { |phone_number| person_one.phone_numbers << phone_number } }
    let!(:phone_number_two) { create(:phone_number, number: '+1234567890').tap { |phone_number| person_two.phone_numbers << phone_number } }

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end
end
