require 'rails_helper'

describe CsvImport do
  let!(:csv_import) { build(:csv_import, tags: 'csv, test') }
  let!(:import) { CsvImport.new(csv_import) }

  before do
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

  context 'csv file quirks' do
    before do
      csv_import.update(in_preview: true)
      csv_import.file_headers_mappings = {
        'Church'               => 'Church',
        'City'                 => 'Mailing City',
        'Commitment Amount'    => 'Commitment Amount',
        'Commitment Currency'  => 'Commitment Currency',
        'Commitment Frequency' => 'Commitment Frequency',
        'Contact Name'         => 'Contact Name',
        'Country'              => 'Mailing Country',
        'Email 1'              => 'Primary Email',
        'Envelope Greeting'    => 'Envelope Greeting',
        'First Name'           => 'First Name',
        'Greeting'             => 'Greeting',
        'Last Name'            => 'Last Name',
        'Newsletter'           => 'Newsletter',
        'Notes'                => 'Notes',
        'Phone 1'              => 'Primary Phone',
        'Spouse Email'         => 'Spouse Email',
        'Spouse First Name'    => 'Spouse First Name',
        'Spouse Phone'         => 'Spouse Phone',
        'State'                => 'Mailing State',
        'Status'               => 'Status',
        'Street'               => 'Mailing Street Address',
        'Tags'                 => 'Tags',
        'Zip'                  => 'Mailing Postal Code'
      }
      csv_import.file_constants_mappings = {
        'Commitment Currency' => {
          'CAD' => 'CAD'
        },
        'Commitment Frequency' => {
          '1.0' => 'Monthly'
        },
        'Newsletter' => {
          'Both' => 'Both'
        },
        'Status' => {
          'Partner - Pray' => 'Partner - Pray'
        }
      }
    end

    it 'does not error if the csv file has a byte order mark' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_with_bom.csv')))
      import.update_cached_file_data
      csv_import.update(in_preview: false)
      expect { import.import }.to change { Contact.count }.from(0).to(1)
      contact = Contact.first
      expect(contact.account_list).to eq(csv_import.account_list)
      expect(contact.to_s).to eq('Doe, John and Jane')
    end

    it 'does not error if the csv file has a non-utf-8 encoding' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_iso_8950_1.csv')))
      import.update_cached_file_data
      csv_import.file_constants_mappings = {
        'Commitment Currency' => {
          'CAD' => nil
        },
        'Commitment Frequency' => {
          nil => nil
        },
        'Newsletter' => {
          nil => nil
        },
        'Status' => {
          'Partner - Pray' => nil
        }
      }
      csv_import.update(in_preview: false)
      expect { import.import }.to change { Contact.count }.from(0).to(1)
      expect(Contact.first.name).to eq('Lané, John')
    end

    it 'changes None to an empty string in the send newsletter field' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_with_none.csv')))
      import.update_cached_file_data
      csv_import.file_constants_mappings['Newsletter'] = {
        nil => 'None'
      }
      csv_import.update(in_preview: false)
      expect { import.import }.to change { Contact.count }.from(0).to(1)
      expect(Contact.first.send_newsletter).to eq(nil)
    end

    it 'does not error if csv file uses inconsistent newlines like \n then later \r\n' do
      csv_import.update(file: File.new(Rails.root.join('spec/fixtures/sample_csv_inconsistent_newlines.csv')))
      import.update_cached_file_data
      csv_import.update(in_preview: false)
      expect { import.import }.to change { Contact.count }.from(0).to(1)
      expect(Contact.first.name).to eq('Doe, John and Jane')
    end
  end

  context 'with mappings' do
    let!(:csv_import) { create(:csv_import_custom_headers, tags: 'csv, test', in_preview: true) }
    let!(:import) { CsvImport.new(csv_import) }

    before do
      csv_import.file_headers_mappings = {
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

      csv_import.file_constants_mappings = {
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

      import.update_cached_file_data
    end

    describe '#import' do
      it 'parses the csv and saves the contacts' do
        csv_import.in_preview = false
        expect(csv_import).to be_valid
        expect { import.import }.to change(Contact, :count).from(0).to(2)
        expect(csv_import.account_list.contacts.reload.where(name: 'John')).to be_present
      end

      it 'errors if there is invalid data and does not save any contacts' do
        csv_import.in_preview = false
        expect(import).to receive(:contacts).and_return([build(:contact), build(:contact, name: '')])
        expect { import.import }.to raise_error(/Validation failed/)
        expect(Contact.count).to eq(0)
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
    end

    describe '#sample_contacts' do
      it 'returns sample contacts' do
        expect(import.sample_contacts).to be_a Array
        expect(import.sample_contacts.size).to eq 2
        expect(import.sample_contacts.first.name).to eq 'John'
        expect(import.sample_contacts.second.name).to eq 'Joe'
        import.sample_contacts.each do |sample_contact|
          expect(sample_contact).to be_a Contact
          expect(sample_contact.uuid).to be_present
          expect(Contact.find_by(uuid: sample_contact.uuid)).to be_blank
        end
      end
    end
  end

  describe '#update_cached_file_data' do
    it 'assigns file_headers when setting file' do
      import = create(:csv_import_custom_headers, in_preview: true)
      csv_import = CsvImport.new(import)
      expect { csv_import.update_cached_file_data }.to change { import.reload.file_headers }.from([]).to %w(fname
                                                                                                            lname
                                                                                                            Spouse-fname
                                                                                                            Spouse-lname
                                                                                                            greeting
                                                                                                            mailing-greeting
                                                                                                            church
                                                                                                            street
                                                                                                            city
                                                                                                            province
                                                                                                            zip-code
                                                                                                            country
                                                                                                            status
                                                                                                            amount
                                                                                                            frequency
                                                                                                            currency
                                                                                                            newsletter
                                                                                                            tags
                                                                                                            email-address
                                                                                                            Spouse-email-address
                                                                                                            phone
                                                                                                            Spouse-phone-number
                                                                                                            extra-notes
                                                                                                            skip
                                                                                                            likely-giver
                                                                                                            metro
                                                                                                            region
                                                                                                            appeals
                                                                                                            website)
    end

    it 'assigns file_constants when setting file' do
      import = create(:csv_import_custom_headers, in_preview: true)
      csv_import = CsvImport.new(import)
      expect { csv_import.update_cached_file_data }.to change { import.reload.file_constants }.from({}).to(
        'greeting' => Set.new(['Hi John and Jane', 'Hello!', nil]),
        'status' => Set.new(['Praying', 'Praying and giving']),
        'amount' => Set.new(['50', '10', nil]),
        'frequency' => Set.new(['Monthly', nil]),
        'newsletter' => Set.new(['Both']),
        'currency' => Set.new(['CAD', nil]),
        'skip' => Set.new(['No', 'Yes', nil]),
        'likely-giver' => Set.new(%w(Yes No)),
        'appeals' => Set.new(%w(Yes No))
      )
    end

    it 'assigns file_row_samples when setting file' do
      import = create(:csv_import_custom_headers, in_preview: true)
      csv_import = CsvImport.new(import)
      expect { csv_import.update_cached_file_data }.to change { import.reload.file_row_samples }.from([]).to(
        [
          ['John', 'Doe', 'Jane', 'Doe', 'Hi John and Jane', 'Doe family', 'Westside Baptist Church',
           '1 Example Ave, Apt 6', 'Sample City', 'IL', '60201', 'USA', 'Praying', '50', 'Monthly', 'CAD',
           'Both', 'christmas-card,      family', 'john@example.com', 'jane@example.com', '(213) 222-3333',
           '(407) 555-6666', 'test notes', 'No', 'Yes', 'metro', 'region', 'Yes', 'http://www.john.doe'],
          ['Bob', 'Park', 'Sara', 'Kim', 'Hello!', nil, nil, '123 Street West', 'A Small Town', 'Quebec',
           'L8D 3B9', 'Canada', 'Praying and giving', '10', 'Monthly', nil, 'Both', 'bob', 'bob@park.com',
           'sara@kim.com', '+12345678901', '+10987654321', nil, 'Yes', 'No', 'metro', 'region', 'No', 'website'],
          ['Joe', 'Man', nil, nil, nil, nil, nil, 'Apartment, Unit 123', 'Big City', 'BC', nil, 'CA', 'Praying',
           nil, nil, nil, 'Both', nil, 'joe@inter.net', nil, '123.456.7890', nil, 'notes', nil, 'Yes', 'metro',
           'region', 'Yes', 'website']
        ]
      )
    end
  end
end
