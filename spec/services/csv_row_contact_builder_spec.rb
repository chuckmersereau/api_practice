require 'rails_helper'

describe CsvRowContactBuilder do
  let!(:import) { create(:csv_import_custom_headers, tags: 'csv, test', in_preview: true) }
  let!(:csv_row) { CSV.new(File.open(import.file_path).read, headers: :first_row).first }
  let!(:existing_contact) { create(:contact, name: 'Mary Kim', account_list: import.account_list) }

  subject { CsvRowContactBuilder.new(import: import, csv_row: csv_row) }

  before do
    CsvImport.new(import).update_cached_file_data

    import.file_headers_mappings = {
      'church'               => 'church',
      'city'                 => 'city',
      'commitment_amount'    => 'amount',
      'commitment_currency'  => 'currency',
      'commitment_frequency' => 'frequency',
      'contact_name'         => 'fname',
      'country'              => 'country',
      'email_1'              => 'email_address',
      'first_name'           => 'fname',
      'full_name'            => 'fullname',
      'greeting'             => 'greeting',
      'envelope_greeting'    => 'mailing_greeting',
      'last_name'            => 'lname',
      'likely_to_give'       => 'likely_giver',
      'metro_area'           => 'metro',
      'newsletter'           => 'newsletter',
      'notes'                => 'extra_notes',
      'phone_1'              => 'phone',
      'referred_by'          => 'referred_by',
      'region'               => 'region',
      'send_appeals'         => 'appeals',
      'spouse_email'         => 'spouse_email_address',
      'spouse_first_name'    => 'spouse_fname',
      'spouse_last_name'     => 'spouse_lname',
      'spouse_phone'         => 'spouse_phone_number',
      'state'                => 'province',
      'status'               => 'status',
      'street'               => 'street',
      'tags'                 => 'tags',
      'website'              => 'website',
      'zip'                  => 'zip_code'
    }

    import.file_constants_mappings = {
      'commitment_currency' => {
        'cad' => ['CAD'],
        'usd' => ''
      },
      'commitment_frequency' => {
        '1_0' => 'Monthly',
        '' => ''
      },
      'likely_to_give' => {
        'most_likely' => 'Yes',
        'least_likely' => 'No'
      },
      'newsletter' => {
        'both' => 'Both'
      },
      'send_appeals' => {
        'true' => ['Yes'],
        'false' => ['No']
      },
      'status' => {
        'partner_financial' => 'Praying and giving',
        'partner_pray' => ['Praying']
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
      expect(contact.name).to eq('Doe, John and Jane')
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

      expect(contact.contact_referrals_to_me.size).to eq(1)
      contact_referral = contact.contact_referrals_to_me.first
      expect(contact_referral.referred_by.name).to eq('Mary Kim')
    end

    context 'referred_by cannot be found' do
      it 'adds referred_by to contact notes and tag' do
        Contact.delete_all
        contact = subject.build
        expect(contact.contact_referrals_to_me.size).to eq(0)
        expect(contact.notes).to include('Referred by: Mary Kim')
        expect(contact.tag_list).to include('missing csv referred by')
      end
    end
  end

  describe 'name parsing' do
    context 'all name fields are specified' do
      before do
        %w(full_name first_name last_name spouse_first_name spouse_last_name).each do |required_key|
          raise unless import.file_headers_mappings.keys.include?(required_key)
        end
      end

      it 'builds names' do
        contact = subject.build
        expect(contact.name).to eq('Doe, John and Jane')
        person = contact.primary_person
        expect(person.first_name).to eq('John')
        expect(person.last_name).to eq('Doe')
        spouse = contact.spouse
        expect(spouse.first_name).to eq('Jane')
        expect(spouse.last_name).to eq('Doe')
      end
    end

    context 'full_name field is not specified, but other name fields are' do
      before do
        import.file_headers_mappings.delete('full_name')
      end

      it 'builds names' do
        contact = subject.build
        expect(contact.name).to eq('Doe, John and Jane')
        person = contact.primary_person
        expect(person.first_name).to eq('John')
        expect(person.last_name).to eq('Doe')
        spouse = contact.spouse
        expect(spouse.first_name).to eq('Jane')
        expect(spouse.last_name).to eq('Doe')
      end
    end

    context 'full_name field is specified, but other name fields are not' do
      before do
        import.file_headers_mappings.delete('first_name')
        import.file_headers_mappings.delete('last_name')
        import.file_headers_mappings.delete('spouse_first_name')
        import.file_headers_mappings.delete('spouse_last_name')
      end

      it 'builds names' do
        contact = subject.build
        expect(contact.name).to eq('Doey, Johnny and Janey')
        person = contact.primary_person
        expect(person.first_name).to eq('Johnny')
        expect(person.last_name).to eq('Doey')
        spouse = contact.spouse
        expect(spouse.first_name).to eq('Janey')
        expect(spouse.last_name).to eq('Doey')
      end
    end
  end
end
