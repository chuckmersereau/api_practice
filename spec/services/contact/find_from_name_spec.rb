require 'rails_helper'

RSpec.describe Contact::FindFromName, type: :model do
  let!(:contact_one) { create(:contact_with_person, name: 'Bob, Billy').reload }
  let!(:contact_two) { create(:contact_with_person, name: 'Jane, Janey').reload }

  it 'initializes' do
    expect(Contact::FindFromName.new(Contact.all, 'test')).to be_a(Contact::FindFromName)
  end

  describe '#first' do
    it 'finds an exact match on the name' do
      Person.delete_all
      expect(Contact::FindFromName.new(Contact.all, 'Bob, Billy').first).to eq(contact_one)
    end

    it 'finds a match on the name by parsing full name' do
      Person.delete_all
      expect(Contact::FindFromName.new(Contact.all, 'Billy Bob').first).to eq(contact_one)
    end

    it 'finds an exact match on the greeting' do
      Person.delete_all
      contact_one.update(greeting: 'Mr. Man')
      expect(Contact::FindFromName.new(Contact.all, contact_one.greeting).first).to eq(contact_one)
    end

    it 'finds a match on the greeting by parsing full name' do
      Person.delete_all
      contact_one.update(greeting: 'McBilly, Bobby and Janey')
      expect(Contact::FindFromName.new(Contact.all, 'Bobby and Janey McBilly').first).to eq(contact_one)
    end

    it 'finds a match on the greeting by parsing just first name' do
      Person.delete_all
      contact_one.update(greeting: 'Bobby and Janey')
      expect(Contact::FindFromName.new(Contact.all, 'Doe, Bobby & Janey').first).to eq(contact_one)
    end

    it 'finds an exact match on the person first and last name' do
      contact_one.update(name: 'Something irrelevant')
      expect(Contact::FindFromName.new(Contact.all, "#{contact_one.people.first.last_name}, #{contact_one.people.first.first_name}").first).to eq(contact_one)
    end

    it 'scopes the query' do
      expect(Contact::FindFromName.new(Contact.where(name: contact_one.name), contact_two.name).first).to be_nil
      expect(Contact::FindFromName.new(Contact.where(name: contact_two.name), contact_two.name).first).to eq(contact_two)
    end
  end
end
