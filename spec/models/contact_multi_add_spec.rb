require 'spec_helper'

describe ContactMultiAdd do
  let(:account_list) { create(:account_list) }
  subject { ContactMultiAdd.new(account_list) }
  let(:contact_attrs) do
    { first_name: 'John', last_name: 'Doe', spouse_first_name: 'Jane',
      notes: 'Notes', email: 'john@example.com', phone: '213-222-3333',
      spouse_email: 'jane@example.com', spouse_phone: '407-555-6666',
      street: '1 Way', city: 'Somewhere', state: 'IL', postal_code: '60660' }
  end

  before { stub_smarty_streets }

  context '#add_contacts' do
    it 'adds contacts with correct fields' do
      expect do
        @contacts, @bad_count = subject.add_contacts(0 => contact_attrs)
      end.to change(Contact, :count).by(1)

      expect(@bad_count).to eq(0)
      expect(@contacts.count).to eq(1)

      contact = @contacts.first
      expect(contact.account_list).to eq(account_list)
      expect(contact.notes).to eq('Notes')
      expect(contact.greeting).to eq('John & Jane')
      expect(contact.name).to eq('Doe, John & Jane')
      expect(contact.addresses.count).to eq(1)

      address = contact.addresses.first
      expect(address.street).to eq('1 Way')
      expect(address.city).to eq('Somewhere')
      expect(address.state).to eq('IL')
      expect(address.primary_mailing_address).to be_truthy
      expect(address.postal_code).to eq('60660')

      expect(contact.people.count).to eq(2)

      john = contact.people.first
      expect(john.first_name).to eq('John')
      expect(john.last_name).to eq('Doe')
      expect(john.phone_numbers.count).to eq(1)
      expect(john.phone_numbers.first.number).to eq('+12132223333')
      expect(john.email_addresses.count).to eq(1)
      expect(john.email_addresses.first.email).to eq('john@example.com')

      jane = contact.people.second
      expect(jane.first_name).to eq('Jane')
      expect(jane.last_name).to eq('Doe')
      expect(jane.phone_numbers.count).to eq(1)
      expect(jane.phone_numbers.first.number).to eq('+14075556666')
      expect(jane.email_addresses.count).to eq(1)
      expect(jane.email_addresses.first.email).to eq('jane@example.com')
    end

    it 'ignores fully blank rows' do
      attrs = {
        0 => contact_attrs,
        1 => { first_name: '', last_name: ' ' }
      }
      expect do
        @contacts, @bad_count = subject.add_contacts(attrs)
      end.to change(Contact, :count).by(1)
      expect(@bad_count).to eq(0)
    end

    it 'counts rows with no first or last name as a bad row' do
      contacts, bad_count = subject.add_contacts(0 => { street: 'some data' })
      expect(bad_count).to eq(1)
      expect(contacts).to be_empty
    end

    it 'counts a row with a bad email as bad' do
      contacts, bad_count = subject.add_contacts(0 => { last_name: 'Doe', email: 'bad' })
      expect(bad_count).to eq(1)
      expect(contacts).to be_empty
    end

    it 'defaults one unspecified first or last name to Unknown' do
      attrs = { 0 => { first_name: 'John' }, 1 => { last_name: 'Doe' } }
      expect do
        @contacts, @bad_count = subject.add_contacts(attrs)
      end.to change(Contact, :count).by(2)
      expect(@bad_count).to eq(0)
      expect(@contacts.first.last_name).to eq('Unknown')
      expect(@contacts.second.first_name).to eq('Unknown')
    end

    it 'sets the referrer if specified' do
      referrer = create(:contact)
      ContactMultiAdd.new(account_list, referrer).add_contacts(0 => contact_attrs)
      expect(account_list.contacts.last.referrals_to_me.to_a).to eq([referrer])
    end
  end
end
