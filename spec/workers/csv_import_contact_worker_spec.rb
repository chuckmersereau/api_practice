require 'rails_helper'

describe CsvImportContactWorker do
  let!(:import) { create(:csv_import_with_mappings) }
  let!(:csv_import) { CsvImport.new(import) }
  let(:csv_rows) do
    csv_rows = []
    csv_import.each_row { |csv_row| csv_rows << csv_row }
    csv_rows
  end

  before do
    Sidekiq::Testing.inline!
    stub_smarty_streets
  end

  it 'creates a contact' do
    csv_row = csv_rows.first
    expect do
      CsvImportContactWorker.new.perform(import.id, csv_row.headers, csv_row.fields)
    end.to change { Contact.count }.from(0).to(1)
  end

  context 'ActiveRecord::RecordInvalid exception raised when saving contact' do
    let(:csv_row) do
      csv_row = csv_rows.first.to_h
      csv_row['fullname'] = nil
      csv_row['fname'] = nil
      csv_row['lname'] = nil
      CSV::Row.new(csv_row.keys, csv_row.values)
    end

    it 'adds failed line to file_row_failures' do
      expect(import.reload.file_row_failures).to eq([])
      expect do
        CsvImportContactWorker.new.perform(import.id, csv_row.headers, csv_row.fields)
      end.to_not change { Contact.count }.from(0)
      failing_row = ["Validation failed: First name can't be blank", nil, nil, nil, 'Jane ', 'Doe',
                     'Hi John and Jane', 'Doe family', 'Westside Baptist Church',
                     '1 Example Ave, Apt 6', 'Sample City', 'IL', '60201', 'USA', 'Praying', '50',
                     'Monthly', 'CAD', 'Both', 'christmas-card,      family', ' john@example.com ',
                     ' jane@example.com ', '(213) 222-3333', '(407) 555-6666', 'test notes', 'No',
                     'Yes', 'metro', 'region', 'Yes', 'http://www.john.doe', 'Mary Kim']
      expect(import.reload.file_row_failures).to eq([failing_row])
    end

    it 'does not report to Rollbar' do
      expect(Rollbar).to_not receive(:error)
      CsvImportContactWorker.new.perform(import.id, csv_row.headers, csv_row.fields)
    end
  end

  context 'ActiveRecord::RecordNotUnique exception raised when saving contact' do
    let(:csv_row) { csv_rows.first }

    before do
      expect(CsvRowContactBuilder).to receive(:new).exactly(1).times
                                                   .and_raise(ActiveRecord::RecordNotUnique, 'just testing')
    end

    it 'adds failed line to file_row_failures' do
      expect(import.reload.file_row_failures).to eq([])
      expect do
        CsvImportContactWorker.new.perform(import.id, csv_row.headers, csv_row.fields)
      end.to_not change { Contact.count }.from(0)
      failing_row = ['Record not unique error: Please ensure you are not importing duplicate '\
                       'data (such as duplicate email addresses, which must be unique)',
                     'Johnny and Janey Doey', ' John', 'Doe', 'Jane ', 'Doe', 'Hi John and Jane',
                     'Doe family', 'Westside Baptist Church', '1 Example Ave, Apt 6', 'Sample City',
                     'IL', '60201', 'USA', 'Praying', '50', 'Monthly', 'CAD', 'Both',
                     'christmas-card,      family', ' john@example.com ', ' jane@example.com ',
                     '(213) 222-3333', '(407) 555-6666', 'test notes', 'No', 'Yes', 'metro',
                     'region', 'Yes', 'http://www.john.doe', 'Mary Kim']
      expect(import.reload.file_row_failures).to eq([failing_row])
    end

    it 'does not report to Rollbar' do
      expect(Rollbar).to_not receive(:error)
      CsvImportContactWorker.new.perform(import.id, csv_row.headers, csv_row.fields)
    end
  end

  context 'unknown exception raised when saving contact' do
    let(:csv_row) { csv_rows.first }

    before do
      expect(CsvRowContactBuilder).to receive(:new).exactly(4).times.and_raise(StandardError)
      expect(Rollbar).to receive(:error).exactly(4).times
    end

    it 'adds failed line to file_row_failures' do
      expect(import.reload.file_row_failures).to eq([])
      expect do
        CsvImportContactWorker.new.perform(import.id, csv_row.headers, csv_row.fields)
      end.to_not change { Contact.count }.from(0)
      failing_row = ['StandardError', 'Johnny and Janey Doey', ' John', 'Doe', 'Jane ', 'Doe',
                     'Hi John and Jane', 'Doe family', 'Westside Baptist Church',
                     '1 Example Ave, Apt 6', 'Sample City', 'IL', '60201', 'USA', 'Praying', '50',
                     'Monthly', 'CAD', 'Both', 'christmas-card,      family', ' john@example.com ',
                     ' jane@example.com ', '(213) 222-3333', '(407) 555-6666', 'test notes', 'No',
                     'Yes', 'metro', 'region', 'Yes', 'http://www.john.doe', 'Mary Kim']
      expect(import.reload.file_row_failures).to eq([failing_row])
    end
  end
end
