require 'rails_helper'

describe CsvImportContactWorker do
  let!(:import) { create(:csv_import_with_mappings) }
  let!(:csv_import) { CsvImport.new(import) }
  let(:csv_lines) do
    lines = []
    import.each_line { |line, _file| lines << line }
    lines
  end

  before do
    Sidekiq::Testing.inline!
    stub_request(:get, %r{api.smartystreets.com/.*})
      .with(headers: { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: '{}', headers: {})
  end

  context 'csv line is a comma delimited string' do
    it 'creates a contact' do
      csv_line = csv_lines.second
      expect(csv_line).to be_a String
      expect { CsvImportContactWorker.new.perform(import.id, csv_line) }.to change { Contact.count }.from(0).to(1)
    end
  end

  context 'csv line is an array' do
    it 'creates a contact' do
      csv_line = CSV.new(csv_lines.second).first
      expect(csv_line).to be_a Array
      expect { CsvImportContactWorker.new.perform(import.id, csv_line) }.to change { Contact.count }.from(0).to(1)
    end
  end

  context 'ActiveRecord::RecordInvalid exception raised when build contact' do
    let(:csv_line) do
      csv_line = CSV.new(csv_lines.second).first
      csv_line[0] = nil
      csv_line[1] = nil
      csv_line
    end

    it 'adds failed line to file_row_failures' do
      expect(import.reload.file_row_failures).to eq([])
      expect { CsvImportContactWorker.new.perform(import.id, csv_line) }.to_not change { Contact.count }.from(0)
      expect(import.reload.file_row_failures).to eq([["Validation failed: First name can't be blank", nil, nil, 'Jane',
                                                      'Doe', 'Hi John and Jane', 'Doe family',
                                                      'Westside Baptist Church', '1 Example Ave, Apt 6', 'Sample City',
                                                      'IL', '60201', 'USA', 'Praying', '50', 'Monthly', 'CAD', 'Both',
                                                      'christmas-card,      family', 'john@example.com', 'jane@example.com',
                                                      '(213) 222-3333', '(407) 555-6666', 'test notes', 'No', 'Yes', 'metro',
                                                      'region', 'Yes', 'http://www.john.doe']])
    end

    it 'does not report to Rollbar' do
      expect(Rollbar).to_not receive(:error)
      CsvImportContactWorker.new.perform(import.id, csv_line)
    end
  end

  context 'unknown exception raised when build contact' do
    before do
      expect_any_instance_of(CsvRowContactBuilder).to receive(:build).and_raise(StandardError)
    end

    it 'adds failed line to file_row_failures' do
      expect(Rollbar).to receive(:error).once
      expect(import.reload.file_row_failures).to eq([])
      expect { CsvImportContactWorker.new.perform(import.id, csv_lines.second) }.to_not change { Contact.count }.from(0)
      expect(import.reload.file_row_failures).to eq([['StandardError', 'John', 'Doe', 'Jane', 'Doe', 'Hi John and Jane', 'Doe family',
                                                      'Westside Baptist Church', '1 Example Ave, Apt 6', 'Sample City',
                                                      'IL', '60201', 'USA', 'Praying', '50', 'Monthly', 'CAD', 'Both',
                                                      'christmas-card,      family', 'john@example.com', 'jane@example.com',
                                                      '(213) 222-3333', '(407) 555-6666', 'test notes', 'No', 'Yes', 'metro',
                                                      'region', 'Yes', 'http://www.john.doe']])
    end
  end
end
