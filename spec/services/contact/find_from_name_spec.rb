require 'rails_helper'

RSpec.describe Contact::FindFromName, type: :model do
  let!(:contact_one) { create(:contact_with_person, name: 'Bob, Billy').reload }
  let!(:contact_two) { create(:contact_with_person, name: 'Jane, Janey').reload }

  it 'initializes' do
    expect(described_class.new(Contact.all, 'test')).to be_a(described_class)
  end

  describe '#first' do
    it 'finds an exact match on the name' do
      Person.delete_all
      expect(described_class.new(Contact.all, 'Bob, Billy').first).to eq(contact_one)
    end

    it 'finds a match on the name by parsing full name' do
      Person.delete_all
      expect(described_class.new(Contact.all, 'Billy Bob').first).to eq(contact_one)
    end

    it 'finds an exact match on the greeting' do
      Person.delete_all
      contact_one.update(greeting: 'Mr. Man')
      expect(described_class.new(Contact.all, contact_one.greeting).first).to eq(contact_one)
    end

    it 'finds a match on the greeting by parsing full name' do
      Person.delete_all
      contact_one.update(greeting: 'Mcbilly, Bobby and Janey')
      expect(described_class.new(Contact.all, 'Bobby and Janey Mcbilly').first).to eq(contact_one)
    end

    it 'finds a match on the greeting by parsing just first name' do
      Person.delete_all
      contact_one.update(greeting: 'Bobby and Janey')
      expect(described_class.new(Contact.all, 'Doe, Bobby & Janey').first).to eq(contact_one)
    end

    it 'finds an exact match on the person first and last name' do
      contact_one.update(name: 'Something irrelevant')
      names = "#{contact_one.people.first.last_name}, #{contact_one.people.first.first_name}"
      expect(described_class.new(Contact.all, names).first).to eq(contact_one)
    end

    it 'scopes the query' do
      expect(described_class.new(Contact.where(name: contact_one.name), contact_two.name).first).to be_nil
      expect(described_class.new(Contact.where(name: contact_two.name), contact_two.name).first).to eq(contact_two)
    end
  end
end
