require 'rails_helper'

describe CsvImport do
  let!(:csv_import) { build(:csv_import, tags: 'csv, test') }
  let!(:import) { CsvImport.new(csv_import) }

  before do
    Sidekiq::Testing.inline!
    stub_request(:get, %r{api.smartystreets.com/.*})
      .with(headers: { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: '{}', headers: {})
  end

  it 'defines constants that are consistent with the supported headers' do
    expect(CsvImport::SUPPORTED_HEADERS & CsvImport::CONSTANT_HEADERS.keys).to eq CsvImport::CONSTANT_HEADERS.keys
  end

  it 'defines required headers that are consistent with the supported headers' do
    expect(CsvImport::SUPPORTED_HEADERS & CsvImport::REQUIRED_HEADERS).to eq CsvImport::REQUIRED_HEADERS
  end

  describe '.supported_headers' do
    it 'returns a Hash of Strings' do
      expect(CsvImport.supported_headers).to be_a_hash_with_types(String, String)
    end
  end

  describe '.supported_headers_hashes' do
    it 'returns an Array of Hashes' do
      expect(CsvImport.supported_headers_hashes).to be_a(Array)
      CsvImport.supported_headers_hashes.each do |hash|
        expect(hash).to be_a_hash_with_types(String, String)
      end
    end
  end

  describe '.required_headers' do
    it 'returns a Hash of Strings' do
      expect(CsvImport.required_headers).to be_a_hash_with_types(String, String)
    end
  end

  describe '.required_headers_hashes' do
    it 'returns an Array of Hashes' do
      expect(CsvImport.required_headers_hashes).to be_a(Array)
      CsvImport.required_headers_hashes.each do |hash|
        expect(hash).to be_a_hash_with_types(String, String)
      end
    end
  end

  describe '.constants' do
    it 'returns a Hash of Hashes' do
      expect(CsvImport.constants).to be_a_hash_with_types(String, Hash)
    end
  end

  describe '.constants_hashes' do
    it 'returns an Array of Hashes' do
      expect(CsvImport.constants_hashes).to be_a(Array)
      CsvImport.constants_hashes.each do |hash|
        expect(hash).to be_a(Hash)
        expect(hash['id']).to be_a(String)
        expect(hash['values']).to be_a(Array)
      end
    end
  end

  describe '#each_row' do
    let!(:csv_import) { build(:csv_import_custom_headers) }
    let!(:import) { CsvImport.new(csv_import) }

    it 'enumerates through the csv rows' do
      rows = []
      import.each_row do |csv_row|
        expect(csv_row).to be_a(CSV::Row)
        expect(csv_row.headers).to be_present
        expect(csv_row.fields).to be_present
        rows << csv_row
      end
      expect(rows.size).to eq(3)
    end
  end

  context 'csv file quirks' do
    before do
      csv_import.update(in_preview: true)
      csv_import.file_headers_mappings = {
        'church'               => 'church',
        'city'                 => 'mailing_city',
        'commitment_amount'    => 'commitment_amount',
        'commitment_currency'  => 'commitment_currency',
        'commitment_frequency' => 'commitment_frequency',
        'country'              => 'mailing_country',
        'email_1'              => 'primary_email',
        'envelope_greeting'    => 'envelope_greeting',
        'first_name'           => 'first_name',
        'greeting'             => 'greeting',
        'last_name'            => 'last_name',
        'newsletter'           => 'newsletter',
        'notes'                => 'notes',
        'phone_1'              => 'primary_phone',
        'spouse_email'         => 'spouse_email',
        'spouse_first_name'    => 'spouse_first_name',
        'spouse_phone'         => 'spouse_phone',
        'state'                => 'mailing_state',
        'status'               => 'status',
        'street'               => 'mailing_street_address',
        'tags'                 => 'tags',
        'zip'                  => 'mailing_postal_code'
      }
      csv_import.file_constants_mappings = {
        'commitment_currency' => [
          { 'id' => 'CAD', values: ['CAD'] }
        ],
        'commitment_frequency' => [
          { 'id' => '1.0', values: ['Monthly'] }
        ],
        'newsletter' => [
          { 'id' => 'Both', values: ['Both'] }
        ],
        'status' => [
          { 'id' => 'Partner - Pray', values: ['Partner - Pray'] }
        ]
      }
    end

    it 'does not error if the csv file has a byte order mark' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_with_bom.csv')))
      import.update_cached_file_data
      csv_import.update(in_preview: false)
      expect { import.import }.to change { Contact.count }.from(1).to(2)
      contact = Contact.first
      expect(contact.account_list).to eq(csv_import.account_list)
      expect(contact.to_s).to eq('Doe, John and Jane')
    end

    it 'does not error if the csv file has a non-utf-8 encoding' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_iso_8950_1.csv')))
      import.update_cached_file_data
      csv_import.file_constants_mappings = {
        'commitment_currency' => {
          'cad' => ''
        },
        'commitment_frequency' => {
          '' => ''
        },
        'newsletter' => {
          '' => ''
        },
        'status' => {
          'partner_pray' => ''
        }
      }
      csv_import.update(in_preview: false)
      expect { import.import }.to change { Contact.count }.from(1).to(2)
      expect(Contact.first.name).to eq('Lané, John')
    end

    it 'changes None to an empty string in the send newsletter field' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_with_none.csv')))
      import.update_cached_file_data
      csv_import.file_constants_mappings['newsletter'] = {
        '' => 'None'
      }
      csv_import.update(in_preview: false)
      expect { import.import }.to change { Contact.count }.from(1).to(2)
      expect(Contact.first.send_newsletter).to eq('')
    end

    it 'does not error if csv file uses inconsistent newlines like \n then later \r\n' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_inconsistent_newlines.csv')))
      import.update_cached_file_data
      csv_import.update(in_preview: false)
      expect { import.import }.to change { Contact.count }.from(1).to(2)
      expect(Contact.first.name).to eq('Doe, John and Jane')
    end
  end

  context 'with mappings' do
    let!(:csv_import) { create(:csv_import_custom_headers, tags: 'csv, test', in_preview: true) }
    let!(:import) { CsvImport.new(csv_import) }

    before do
      csv_import.file_headers_mappings = {
        'church'               => 'church',
        'city'                 => 'city',
        'commitment_amount'    => 'amount',
        'commitment_currency'  => 'currency',
        'commitment_frequency' => 'frequency',
        'country'              => 'country',
        'email_1'              => 'email_address',
        'first_name'           => 'fname',
        'greeting'             => 'greeting',
        'envelope_greeting'    => 'mailing_greeting',
        'last_name'            => 'lname',
        'likely_to_give'       => 'likely_giver',
        'metro_area'           => 'metro',
        'newsletter'           => 'newsletter',
        'notes'                => 'extra_notes',
        'phone_1'              => 'phone',
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

      csv_import.file_constants_mappings = {
        'commitment_currency' => {
          'cad' => 'CAD',
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
          'true' => 'Yes',
          'false' => 'No'
        },
        'status' => {
          'partner_financial' => 'Praying and giving',
          'partner_pray' => 'Praying'
        }
      }

      import.update_cached_file_data
    end

    describe '#import' do
      it 'parses the csv and saves the contacts' do
        csv_import.in_preview = false
        expect(csv_import).to be_valid
        expect { import.import }.to change(Contact, :count).from(0).to(3)
        expect(csv_import.account_list.contacts.reload.where(name: 'Doe, John and Jane')).to be_present
      end

      it 'aborts if the import is invalid' do
        csv_import.in_preview = false
        csv_import.file_constants_mappings = nil
        csv_import.file_headers_mappings = nil
        expect(csv_import).to be_invalid
        expect do
          expect { import.import }.to raise_error RuntimeError
        end.not_to change { Contact.count }
      end

      it 'aborts if the import is in preview' do
        csv_import.in_preview = true
        expect(csv_import).to be_valid
        expect do
          expect { import.import }.to raise_error RuntimeError
        end.not_to change { Contact.count }
      end

      it 'returns true when queueing jobs' do
        csv_import.in_preview = false
        expect(import.import).to eq(true)
      end

      it 'returns false if no jobs were queued' do
        allow_any_instance_of(ImportUploader).to receive(:path).and_return(Rails.root.join('spec/fixtures/sample_csv_blank.csv').to_s)
        csv_import.in_preview = false
        expect(import.import).to eq(false)
      end

      it 'queues a sidekiq batch' do
        csv_import.in_preview = false
        expect { import.import }.to change { Sidekiq::BatchSet.new.count }.by(1)
      end

      it 'imports valid contacts successfully and stores invalid contacts in the file_row_failures' do
        allow_any_instance_of(ImportUploader).to receive(:path).and_return(Rails.root.join('spec/fixtures/sample_csv_with_some_invalid_rows.csv').to_s)
        csv_import.in_preview = false
        expect do
          expect(import.import).to eq(true)
        end.to change { Contact.count }.by(1)
        expect(csv_import.reload.file_row_failures.size).to eq(2)
      end

      it 'imports if file_constants is blank' do
        csv_import.file_headers = { 'first_name' => 'first_name', 'church' => 'church' }
        csv_import.file_headers_mappings = { 'first_name' => 'first_name', 'church' => 'church' }
        csv_import.file_constants_mappings = {}
        csv_import.file_constants = {}
        csv_import.in_preview = false
        expect(csv_import).to be_valid
        expect { import.import }.to change(Contact, :count).from(0).to(3)
        expect(csv_import.account_list.contacts.reload.where(name: 'Doe, John and Jane')).to be_present
      end
    end

    describe '#sample_contacts' do
      it 'returns sample contacts' do
        expect(import.sample_contacts).to be_a Array
        expect(import.sample_contacts.size).to eq 3
        expect(import.sample_contacts.first.name).to eq 'Doe, John and Jane'
        expect(import.sample_contacts.second.name).to eq 'Park and Kim, Bob and Sara'
        expect(import.sample_contacts.third.name).to eq 'Man, Joe'
        import.sample_contacts.each do |sample_contact|
          expect(sample_contact).to be_a Contact
          expect(sample_contact.uuid).to be_present
          expect(Contact.find_by(uuid: sample_contact.uuid)).to be_blank
        end
      end

      it 'generates uuids for all of the objects' do
        import.sample_contacts.each do |contact|
          expect(contact.uuid).to be_present
          expect(contact.primary_person.uuid).to be_present
          expect(contact.spouse.uuid).to be_present if contact.spouse
          contact.addresses.each { |address| expect(address.uuid).to be_present }
          contact.primary_person.email_addresses.each { |email_address| expect(email_address.uuid).to be_present }
          contact.spouse.email_addresses.each { |email_address| expect(email_address.uuid).to be_present } if contact.spouse
          contact.primary_person.phone_numbers.each { |phone_number| expect(phone_number.uuid).to be_present }
          contact.spouse.phone_numbers.each { |phone_number| expect(phone_number.uuid).to be_present } if contact.spouse
        end
      end
    end
  end

  describe '#update_cached_file_data' do
    it 'assigns file_headers when setting file' do
      import = create(:csv_import_custom_headers, in_preview: true)
      csv_import = CsvImport.new(import)
      expect { csv_import.update_cached_file_data }.to change { import.reload.file_headers }.from({}).to('fullname' => 'fullname',
                                                                                                         'fname' => 'fname',
                                                                                                         'lname' => 'lname',
                                                                                                         'spouse_fname' => 'Spouse-fname',
                                                                                                         'spouse_lname' => 'Spouse-lname',
                                                                                                         'greeting' => 'greeting',
                                                                                                         'mailing_greeting' => 'mailing-greeting',
                                                                                                         'church' => 'church',
                                                                                                         'street' => 'street',
                                                                                                         'city' => 'city',
                                                                                                         'province' => 'province',
                                                                                                         'zip_code' => 'zip-code',
                                                                                                         'country' => 'country',
                                                                                                         'status' => 'status',
                                                                                                         'amount' => 'amount',
                                                                                                         'frequency' => 'frequency',
                                                                                                         'currency' => 'currency',
                                                                                                         'newsletter' => 'newsletter',
                                                                                                         'tags' => 'tags',
                                                                                                         'email_address' => 'email-address',
                                                                                                         'spouse_email_address' => 'Spouse-email-address',
                                                                                                         'phone' => 'phone',
                                                                                                         'spouse_phone_number' => 'Spouse-phone-number',
                                                                                                         'extra_notes' => 'extra-notes',
                                                                                                         'skip' => 'skip',
                                                                                                         'likely_giver' => 'likely-giver',
                                                                                                         'metro' => 'metro',
                                                                                                         'region' => 'region',
                                                                                                         'appeals' => 'appeals',
                                                                                                         'website' => 'website',
                                                                                                         'referred_by' => 'referred_by')
    end

    it 'assigns file_constants when setting file' do
      import = create(:csv_import_custom_headers, in_preview: true)
      csv_import = CsvImport.new(import)
      expect { csv_import.update_cached_file_data }.to change { import.reload.file_constants }.from({}).to(
        'greeting' => Set.new(['Hi John and Jane', 'Hello!', '']),
        'status' => Set.new(['Praying', 'Praying and giving']),
        'amount' => Set.new(['50', '10', '']),
        'frequency' => Set.new(['Monthly', '']),
        'newsletter' => Set.new(['Both']),
        'currency' => Set.new(['CAD', '']),
        'skip' => Set.new(['No', 'Yes', '']),
        'likely_giver' => Set.new(%w(Yes No)),
        'appeals' => Set.new(%w(Yes No))
      )
    end

    it 'assigns file_row_samples when setting file' do
      import = create(:csv_import_custom_headers, in_preview: true)
      csv_import = CsvImport.new(import)
      expect { csv_import.update_cached_file_data }.to change { import.reload.file_row_samples }.from([]).to(
        [['Johnny and Janey Doey', ' John', 'Doe', 'Jane ', 'Doe', 'Hi John and Jane', 'Doe family', 'Westside Baptist Church',
          '1 Example Ave, Apt 6', 'Sample City', 'IL', '60201', 'USA', 'Praying', '50', 'Monthly', 'CAD',
          'Both', 'christmas-card,      family', ' john@example.com ', ' jane@example.com ', '(213) 222-3333',
          '(407) 555-6666', 'test notes', 'No', 'Yes', 'metro', 'region', 'Yes', 'http://www.john.doe', 'Mary Kim'],
         ['Bobby & Saray Parky', 'Bob', 'Park', 'Sara', 'Kim', 'Hello!', nil, nil, '123 Street West ', 'A Small Town', 'Quebec',
          'L8D 3B9 ', 'Canada', 'Praying and giving', '10', 'Monthly', nil, 'Both', 'bob', 'bob@park.com',
          'sara@kim.com', '+12345678901', '+10987654321', nil, 'Yes', 'No', 'metro', 'region', 'No', 'website', nil],
         ['Joey Many', 'Joe', 'Man', nil, nil, nil, nil, nil, 'Apartment, Unit 123', 'Big City', 'BC', nil, 'CA', 'Praying',
          nil, nil, nil, 'Both', nil, 'joe@inter.net', nil, '123.456.7890', nil, 'notes', nil, 'Yes', 'metro',
          'region', 'Yes', 'website', nil]]
      )
    end
  end

  describe '#generate_csv_from_file_row_failures' do
    let(:import) { create(:csv_import_with_mappings) }
    let(:csv_import) { CsvImport.new(import) }

    before do
      import.in_preview = false
      allow_any_instance_of(ImportUploader).to receive(:path).and_return(Rails.root.join('spec/fixtures/sample_csv_with_some_invalid_rows.csv').to_s)
      csv_import.import
      import.reload
    end

    it 'generates a csv file as a string that contains the failed rows' do
      expect(csv_import.generate_csv_from_file_row_failures).to eq('Error Message,fullname,fname,lname,Spouse-fname,Spouse-lname,greeting,mailing-greeting,church,' \
                                                                   'street,city,province,zip-code,country,status,amount,frequency,currency,newsletter,tags,' \
                                                                   'email-address,Spouse-email-address,phone,Spouse-phone-number,extra-notes,skip,likely-giver' \
                                                                   ",metro,region,appeals,website,referred_by\n\"Validation failed: Email is invalid, Email is invalid\",Bob" \
                                                                   ',Park,Sara,Kim,Hello!,,,123 Street West,A Small Town,Quebec,L8D 3B9,Canada,Praying and giving' \
                                                                   ',10,Monthly,,Both,bob,this is not a valid email,this is also not a valid email,+12345678901' \
                                                                   ",+10987654321,,Yes,No,metro,region,No,website\n\"Validation failed: First name can't be blank, " \
                                                                   "Name can't be blank\",,,,,,,,\"Apartment, Unit 123\",Big City,BC,,CA,Praying,,,,Both,,joe@inter.net" \
                                                                   ",,123.456.7890,,notes,,Yes,metro,region,Yes,website\n")
    end
  end
end
