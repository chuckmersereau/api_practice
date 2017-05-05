require 'rails_helper'

describe CsvFileReader do
  let(:file_path) { Rails.root.join('spec/fixtures/sample_csv_with_custom_headers.csv') }
  let(:service) { CsvFileReader.new(file_path) }

  it 'initializes' do
    expect(service).to be_a CsvFileReader
  end

  describe '#each_row' do
    it 'enumerates through the csv rows' do
      rows = []
      service.each_row do |csv_row|
        expect(csv_row).to be_a(CSV::Row)
        expect(csv_row.headers).to be_present
        expect(csv_row.fields).to be_present
        rows << csv_row
      end
      expect(rows.size).to eq(3)
    end

    it 'skips blank rows' do
      file_path = Rails.root.join('spec/fixtures/sample_csv_with_some_invalid_rows.csv')
      expect(CSV.read(file_path).size).to eq(5)
      service = CsvFileReader.new(file_path)
      rows = []
      service.each_row { |csv_row| rows << csv_row }
      expect(rows.size).to eq(3)
      expect(rows.all? { |row| row.to_h.values.compact.present? }).to eq(true)
    end

    it 'does not error if the csv file has a byte order mark' do
      service = CsvFileReader.new(Rails.root.join('spec/fixtures/sample_csv_with_bom.csv'))
      rows = []
      service.each_row { |csv_row| rows << csv_row }
      expect(rows.size).to eq(1)
      expect(rows.first.headers).to eq(['Contact Name', 'First Name', 'Last Name', 'Spouse First Name', 'Greeting',
                                        'Envelope Greeting', 'Church', 'Mailing Street Address', 'Mailing City',
                                        'Mailing State', 'Mailing Postal Code', 'Mailing Country', 'Status',
                                        'Commitment Amount', 'Commitment Frequency', 'Newsletter', 'Commitment Received',
                                        'Commitment Currency', 'Tags', 'Primary Email', 'Spouse Email', 'Primary Phone',
                                        'Spouse Phone', 'Notes'])
      expect(rows.first.fields).to eq(['Doe, John and Jane', 'John', 'Doe', 'Jane', 'Hi John and Jane', 'Doe family',
                                       'Westside Baptist Church', '1 Example Ave, Apt 6', 'Sample City', 'IL', '60201',
                                       'USA', 'Partner - Pray', '50', 'Monthly', 'Both', 'Yes', 'CAD', 'christmas-card, family',
                                       'john@example.com', 'jane@example.com', '(213) 222-3333', '(407) 555-6666', 'test notes'])
    end

    it 'does not error if the csv file has a non-utf-8 encoding' do
      service = CsvFileReader.new(Rails.root.join('spec/fixtures/sample_csv_iso_8950_1.csv'))
      rows = []
      service.each_row { |csv_row| rows << csv_row }
      expect(rows.size).to eq(1)
      expect(rows.first.headers).to eq(['Contact Name', 'First Name', 'Last Name', 'Spouse First Name', 'Spouse Last Name',
                                        'Greeting', 'Envelope Greeting', 'Church', 'Mailing Street Address', 'Mailing City',
                                        'Mailing State', 'Mailing Postal Code', 'Mailing Country', 'Status', 'Commitment Amount',
                                        'Commitment Frequency', 'Newsletter', 'Commitment Received', 'Commitment Currency', 'Tags',
                                        'Primary Email', 'Spouse Email', 'Primary Phone', 'Spouse Phone', 'Notes'])
      expect(rows.first.fields).to eq(["Lané, John", 'John', "Lané", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                                       nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil])
    end
  end
end
