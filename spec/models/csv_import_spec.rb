require 'spec_helper'

describe CsvImport do
  let!(:csv_import) { build(:csv_import, tags: 'csv, test') }
  let!(:import) { CsvImport.new(csv_import) }

  before do
    stub_request(:get, /api\.smartystreets\.com\/.*/)
      .with(headers: { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: '{}', headers: {})
  end

  def check_contacts(contacts)
    expect(contacts.size).to eq(1)
    contact = contacts.first
    expect(contact.account_list).to eq(csv_import.account_list)
    expect(contact.name).to eq('Doe, John and Jane')
    expect(contact.greeting).to eq('John and Jane')
    expect(contact.envelope_greeting).to eq('John and Jane Doe')
    expect(contact.status).to eq('Partner - Pray')
    expect(contact.pledge_amount).to eq(50)
    expect(contact.notes).to eq('test notes')
    expect(contact.pledge_frequency).to eq(1)
    expect(contact.send_newsletter).to eq('Both')
    expect(contact.pledge_received?).to be true
    expect(contact.tag_list.sort).to eq(%w(christmas-card csv family test))

    address = contact.mailing_address
    expect(address.street).to eq('1 Example Ave, Apt 6')
    expect(address.city).to eq('Sample City')
    expect(address.state).to eq('IL')
    expect(address.postal_code).to eq('60201')
    expect(address.country).to be_nil

    person = contact.primary_person
    expect(person.first_name).to eq('John')
    expect(person.last_name).to eq('Doe')
    expect(person.email_addresses.size).to eq(1)
    expect(person.email_addresses.first.email).to eq('john@example.com')
    expect(person.phone_numbers.size).to eq(1)
    expect(person.phone_numbers.first.number.in?(['(111) 222-3333', '+11112223333'])).to be true

    spouse = contact.spouse
    expect(spouse.first_name).to eq('Jane')
    expect(spouse.last_name).to eq('Doe')
    expect(spouse.email_addresses.size).to eq(1)
    expect(spouse.email_addresses.first.email).to eq('jane@example.com')
    expect(spouse.phone_numbers.size).to eq(1)
    expect(spouse.phone_numbers.first.number.in?(['(444) 555-6666', '+14445556666'])).to be true
  end

  context '#contacts' do
    it 'parses the contacts from csv without saving them' do
      def relevant_record_count
        [Contact, Person, EmailAddress, Address, PhoneNumber].map(&:count).reduce(:+)
      end

      contacts = []
      expect do
        contacts = import.contacts
      end.to_not change(self, :relevant_record_count)
      check_contacts(contacts)
    end

    it 'does not error if the csv file has a byte order mark' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_with_bom.csv')))
      check_contacts(import.contacts)
    end

    it 'does not error if the csv file has a non-utf-8 encoding' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_iso_8950_1.csv')))
      contacts = import.contacts
      expect(contacts.size).to eq(1)
      expect(contacts.first.name).to eq('Lané, John')
    end

    it 'does not error if csv file uses inconsistent newlines like \n then later \r\n' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_inconsistent_newlines.csv')))
      contacts = import.contacts
      expect(contacts.size).to eq(1)
      expect(contacts.first.name).to eq('Doe, John and Jane')
    end
  end

  context '#import' do
    it 'parses the csv and saves the contacts' do
      expect { import.import }.to change(Contact, :count).from(0).to(1)
      check_contacts(csv_import.account_list.contacts.reload)
    end

    it 'errors if there is invalid data and does not save any contacts' do
      expect(import).to receive(:contacts).and_return([build(:contact), build(:contact, name: '')])
      expect { import.import }.to raise_error(/Validation failed/)
      expect(Contact.count).to eq(0)
    end
  end

  context '#contact_from_line' do
    it 'does not error on a blank line' do
      expect { import.contact_from_line({}) }.to_not raise_error
    end
  end
end
