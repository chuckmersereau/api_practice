require 'spec_helper'

describe MasterPerson do
  it 'should create a MasterPerson for a new person' do
    expect do
      MasterPerson.find_or_create_for_person(Person.new)
    end.to change(MasterPerson, :count).by(1)
  end

  it 'should find an existing person based on name and email address' do
    person = create(:person)
    email = create(:email_address, person: person)
    expect do
      person = Person.new(first_name: person.first_name, last_name: person.last_name, suffix: person.suffix)
      person.email = email.email
      person.save!
    end.to_not change(MasterPerson, :count)
  end

  # it "should find an existing person based on name and address" do
  # person = create(:person)
  # address = create(:address, person: person)
  # expect do
  # person = Person.new(first_name: person.first_name, last_name: person.last_name, suffix: person.suffix)
  # person.addresses_attributes = {'0' => address.attributes.with_indifferent_access.slice(:street, :city, :state, :country, :postal_code)}
  # person.save!
  # end.not_to change(MasterPerson, :count)
  # end

  it 'should find an existing person based on name and phone number' do
    person = create(:person)
    phone_number = create(:phone_number, person: person)
    expect do
      person = Person.new(first_name: person.first_name, last_name: person.last_name, suffix: person.suffix)
      person.phone_number = phone_number.attributes.with_indifferent_access.slice(:number, :country_code)
      person.save!
    end.to_not change(MasterPerson, :count)
  end

  it 'should find an existing person based on name and donor account' do
    person = create(:person)
    donor_account = create(:donor_account)
    donor_account.master_people << person.master_person
    donor_account.people << person
    new_person = Person.new(first_name: person.first_name, last_name: person.last_name, suffix: person.suffix)
    expect(MasterPerson.find_for_person(new_person, donor_account: donor_account))
      .to eq(person.master_person)
  end

  it 'deletes people even without callbacks' do
    person = create(:person)

    expect do
      person.master_person.delete
    end.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
