require 'rails_helper'

describe CsvRowContactBuilder do
  let(:import) { create(:csv_import_custom_headers, tags: 'csv, test', in_preview: true) }
  let(:csv_row) { CSV.new(import.file_contents, headers: :first_row).first }

  subject { CsvRowContactBuilder.new(import: import, csv_row: csv_row) }

  before do
    CsvImport.new(import).update_cached_file_data

    import.file_headers_mappings = {
      'Church'               => 'church',
      'City'                 => 'city',
      'Commitment Amount'    => 'amount',
      'Commitment Currency'  => 'currency',
      'Commitment Frequency' => 'frequency',
      'Contact Name'         => 'fname',
      'Country'              => 'country',
      'Do Not Import?'       => 'skip',
      'Email 1'              => 'email-address',
      'First Name'           => 'fname',
      'Greeting'             => 'greeting',
      'Envelope Greeting'    => 'mailing-greeting',
      'Last Name'            => 'lname',
      'Likely To Give'       => 'likely-giver',
      'Metro Area'           => 'metro',
      'Newsletter'           => 'newsletter',
      'Notes'                => 'extra-notes',
      'Phone 1'              => 'phone',
      'Region'               => 'region',
      'Send Appeals?'        => 'appeals',
      'Spouse Email'         => 'Spouse-email-address',
      'Spouse First Name'    => 'Spouse-fname',
      'Spouse Last Name'     => 'Spouse-lname',
      'Spouse Phone'         => 'Spouse-phone-number',
      'State'                => 'province',
      'Status'               => 'status',
      'Street'               => 'street',
      'Tags'                 => 'tags',
      'Website'              => 'website',
      'Zip'                  => 'zip-code'
    }

    import.file_constants_mappings = {
      'Commitment Currency' => {
        'CAD' => 'CAD',
        'USD' => nil
      },
      'Commitment Frequency' => {
        '1.0' => 'Monthly',
        nil => nil
      },
      'Do Not Import?' => {
        'true' => 'Yes',
        'false' => ['No', nil]
      },
      'Likely To Give' => {
        'Most Likely' => 'Yes',
        'Least Likely' => 'No'
      },
      'Newsletter' => {
        'Both' => 'Both'
      },
      'Send Appeals?' => {
        'true' => 'Yes',
        'false' => 'No'
      },
      'Status' => {
        'Partner - Financial' => 'Praying and giving',
        'Partner - Pray' => 'Praying'
      }
    }

    stub_request(:get, %r{api.smartystreets.com/.*})
      .with(headers: { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: '{}', headers: {})
  end

  describe '#build' do
    it 'builds a contact with expected attributes' do
      contact = subject.build

      expect(contact).to be_a Contact

      expect(contact.account_list).to eq(import.account_list)
      expect(['Doe, John and Jane', 'John']).to include(contact.name)
      expect(contact.church_name).to eq('Westside Baptist Church')
      expect(contact.greeting).to eq('Hi John and Jane')
      expect(contact.envelope_greeting).to eq('Doe family')
      expect(contact.status).to eq('Partner - Pray')
      expect(contact.pledge_amount).to eq(50)
      expect(contact.pledge_currency).to eq('CAD')
      expect(contact.notes).to eq('test notes')
      expect(contact.pledge_frequency).to eq(1)
      expect(contact.send_newsletter).to eq('Both')
      expect(contact.tag_list.sort).to eq(%w(christmas-card csv family test))
      expect(contact.likely_to_give).to eq('Most Likely')
      expect(contact.no_appeals).to be(false)
      expect(contact.website).to eq('http://www.john.doe')

      address = contact.mailing_address
      expect(address.street).to eq('1 Example Ave, Apt 6')
      expect(address.city).to eq('Sample City')
      expect(address.state).to eq('IL')
      expect(address.postal_code).to eq('60201')
      expect(address.country).to eq('United States')
      expect(address.metro_area).to eq('metro')
      expect(address.region).to eq('region')
      expect(address.primary_mailing_address).to be(true)

      person = contact.primary_person
      expect(person.first_name).to eq('John')
      expect(person.last_name).to eq('Doe')
      expect(person.email_addresses.size).to eq(1)
      expect(person.email_addresses.first.email).to eq('john@example.com')
      expect(person.phone_numbers.size).to eq(1)
      expect(person.phone_numbers.first.number.in?(['(213) 222-3333', '+12132223333'])).to be(true)

      spouse = contact.spouse
      expect(spouse.first_name).to eq('Jane')
      expect(spouse.last_name).to eq('Doe')
      expect(spouse.email_addresses.size).to eq(1)
      expect(spouse.email_addresses.first.email).to eq('jane@example.com')
      expect(spouse.phone_numbers.size).to eq(1)
      expect(spouse.phone_numbers.first.number.in?(['(407) 555-6666', '+14075556666'])).to be(true)
    end
  end
end
