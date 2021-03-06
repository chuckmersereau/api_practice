require 'rails_helper'

describe Person::DuplicatePairsFinder do
  let!(:account_list) { create(:user_with_account).account_lists.order(:created_at).first }

  let!(:contact) { create(:contact, account_list: account_list) }

  let!(:unique_person_one) do
    create(:person, first_name: 'This person should have no duplicates', last_name: 'No Duplicates').tap do |person|
      person.email_addresses << create(:email_address, email: '121349087191873491@asdflkhasdfghasdlfkhjasdh.com')
      person.phone_numbers << create(:phone_number, number: '21123864192836465189346712893467')
      contact.people << person
    end
  end

  let!(:unique_person_two) do
    create(:person,
           first_name: 'This is another person that is a totally unique individual',
           last_name: 'Totally Unique').tap do |person|
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
    person = create(:person, first_name: 'John', last_name: 'Doe').tap do |created_person|
      contact.people << created_person
    end

    pair_missing_record_one = DuplicateRecordPair.new(
      account_list: account_list,
      reason: 'Test',
      record_one_id: SecureRandom.uuid,
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
      record_two_id: SecureRandom.uuid,
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
    let!(:person_one) do
      create(:person, first_name: 'John', last_name: 'Doe').tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'John', last_name: 'Doe').tap { |person| contact.people << person }
    end

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar names', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same first and last names but different formatting' do
    let!(:person_one) do
      create(:person, first_name: ' john, ', last_name: 'DOE   ').tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: "\nJohn\r", last_name: "Doe'").tap { |person| contact.people << person }
    end

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar names', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same first name but missing last names' do
    let!(:person_one) do
      create(:person, first_name: 'John', last_name: 'Doe').tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'John', last_name: nil).tap { |person| contact.people << person }
    end

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar names', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same first name but different last names' do
    let!(:person_one) do
      create(:person, first_name: 'John', last_name: 'Doe').tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'John', last_name: 'Jones').tap { |person| contact.people << person }
    end

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'people with the same email addresses and same gender' do
    let!(:person_one) do
      create(:person, first_name: 'John', last_name: 'Doe', gender: 'male').tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'Bob', last_name: 'Jones', gender: 'male').tap { |person| contact.people << person }
    end
    let!(:email_address_one) do
      create(:email_address, email: '  duplicate@email.com  ').tap do |email_address|
        person_one.email_addresses << email_address
      end
    end
    let!(:email_address_two) do
      create(:email_address, email: 'Duplicate@Email.COM').tap do |email_address|
        person_two.email_addresses << email_address
      end
    end

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar email addresses', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same email addresses and different gender' do
    let!(:person_one) do
      create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female').tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'Bob', last_name: 'Jones', gender: 'male').tap { |person| contact.people << person }
    end
    let!(:email_address_one) do
      create(:email_address, email: '  duplicate@email.com  ').tap do |email_address|
        person_one.email_addresses << email_address
      end
    end
    let!(:email_address_two) do
      create(:email_address, email: 'Duplicate@Email.COM').tap do |email_address|
        person_two.email_addresses << email_address
      end
    end

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'people with the same email addresses and no gender' do
    let!(:person_one) do
      create(:person, first_name: 'Jane', last_name: 'Doe', gender: nil).tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'Bob', last_name: 'Jones', gender: nil).tap { |person| contact.people << person }
    end
    let!(:email_address_one) do
      create(:email_address, email: '  duplicate@email.com  ').tap do |email_address|
        person_one.email_addresses << email_address
      end
    end
    let!(:email_address_two) do
      create(:email_address, email: 'Duplicate@Email.COM').tap do |email_address|
        person_two.email_addresses << email_address
      end
    end

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'people with the same phone numbers and same gender' do
    let!(:person_one) do
      create(:person, first_name: 'John', last_name: 'Doe', gender: 'male').tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'Bob', last_name: 'Jones', gender: 'male').tap { |person| contact.people << person }
    end
    let!(:phone_number_one) do
      create(:phone_number, number: '1.234.567.890!  ').tap { |phone_number| person_one.phone_numbers << phone_number }
    end
    let!(:phone_number_two) do
      create(:phone_number, number: '+1234567890').tap { |phone_number| person_two.phone_numbers << phone_number }
    end

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Person').where(reason: 'Similar phone numbers', record_one_id: person_one.id,
                                                 record_two_id: person_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'people with the same phone numbers and different gender' do
    let!(:person_one) do
      create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female').tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'Bob', last_name: 'Jones', gender: 'male').tap { |person| contact.people << person }
    end
    let!(:phone_number_one) do
      create(:phone_number, number: '1.234.567.890!  ').tap { |phone_number| person_one.phone_numbers << phone_number }
    end
    let!(:phone_number_two) do
      create(:phone_number, number: '+1234567890').tap { |phone_number| person_two.phone_numbers << phone_number }
    end

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'people with the same phone numbers and no gender' do
    let!(:person_one) do
      create(:person, first_name: 'Jane', last_name: 'Doe', gender: nil).tap { |person| contact.people << person }
    end
    let!(:person_two) do
      create(:person, first_name: 'Bob', last_name: 'Jones', gender: nil).tap { |person| contact.people << person }
    end
    let!(:phone_number_one) do
      create(:phone_number, number: '1.234.567.890!  ').tap { |phone_number| person_one.phone_numbers << phone_number }
    end
    let!(:phone_number_two) do
      create(:phone_number, number: '+1234567890').tap { |phone_number| person_two.phone_numbers << phone_number }
    end

    it 'does not consider them duplicates' do
      expect { build_finder.find_and_save }.to_not change {
        DuplicateRecordPair.count
      }.from(0)
    end
  end

  context 'person with nil phone numbers' do
    let!(:person) do
      create(:person, first_name: 'Jane', last_name: 'Doe', gender: nil).tap { |person| contact.people << person }
    end
    let!(:phone_number) do
      create(:phone_number, number: '1.234.567.890!  ').tap { |phone_number| person.phone_numbers << phone_number }
    end

    before { phone_number.update_column(:number, nil) }

    it 'does not raise a NoMethodError' do
      expect { build_finder.find_and_save }.to_not raise_error
    end
  end
end
