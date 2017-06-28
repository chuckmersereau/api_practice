require 'rails_helper'

describe PersonSerializer do
  let(:person) do
    p = build(:person)
    p.email_addresses << build(:email_address)
    p.phone_numbers << build(:phone_number)
    p
  end

  subject { PersonSerializer.new(person).as_json }

  describe '#parent_contacts' do
    before do
      person.contacts = create_list(:contact, 2)
    end

    it 'returns an array of parent contacts' do
      expect(subject[:parent_contacts].first).to eq(person.contacts.first.uuid)
      expect(subject[:parent_contacts].count).to eq(2)
    end
  end
end
