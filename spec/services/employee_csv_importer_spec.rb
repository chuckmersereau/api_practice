require 'rails_helper'

RSpec.describe EmployeeCsvImporter, type: :service do
  describe 'REQUIRED_HEADERS' do
    it 'returns the correct values' do
      expected_headers = %w(
        email
        first_name
        last_name
        relay_guid
        key_guid
      )

      expect(EmployeeCsvImporter::REQUIRED_HEADERS).to match expected_headers
    end
  end

  describe '#initialize' do
    it 'initializes with a path to a file or URL' do
      importer = build_importer(path: 'https://google.com')

      expect(importer.path).to eq 'https://google.com'
    end
  end

  describe '#converted_data' do
    it 'creates new objects from the row_data' do
      importer = build_importer

      expect(importer.converted_data.count).to eq 100
      expect(importer.converted_data.first).to be_kind_of EmployeeCsvImporter::UserForImport
    end

    it 'returns objects with needed CAS attributes' do
      importer        = build_importer
      user_for_import = importer.converted_data.first

      expected_attributes_for_cas_importer = {
        email: 'adah@kling.biz',
        firstName: 'Adah',
        lastName: 'Huels',
        relayGuid: 'f5472481-bcee-4e9b-b7ad-00407b0eb04f',
        ssoGuid: 'a7d48686-8385-42d6-8cd7-9f33adfab03',
        theKeyGuid: 'a7d48686-8385-42d6-8cd7-9f33adfab03'
      }

      expect(user_for_import.cas_attributes)
        .to eq expected_attributes_for_cas_importer
    end
  end

  describe '#import' do
    it 'delegates a range of converted_data items to UserFromCasService' do
      importer    = build_importer

      first_user  = importer.converted_data[0]
      second_user = importer.converted_data[1]
      third_user  = importer.converted_data[2]

      expect(UserFromCasService)
        .to receive(:find_or_create)
        .with(first_user.cas_attributes)

      expect(UserFromCasService)
        .to receive(:find_or_create)
        .with(second_user.cas_attributes)

      expect(UserFromCasService)
        .to receive(:find_or_create)
        .with(third_user.cas_attributes)

      importer.import(from: 0, to: 2)
    end
  end

  describe '#queue!' do
    it 'will, based on the group size, queue up imports' do
      group_size           = 20
      importer             = build_importer(import_group_size: group_size)
      sidekiq_queue_double = double('sidekiq_queue_double')

      (0..4).each do |num|
        expected_from = (num * group_size)
        expected_to   = expected_from + 19

        expect(EmployeeCsvGroupImportWorker)
          .to receive(:perform_in)
          .with(num.hours, sample_data_path, expected_from, expected_to)
          .and_return(sidekiq_queue_double)
      end

      importer.queue!
    end
  end

  describe '#row_data' do
    context 'with data that has valid headers' do
      it 'returns the rows for the provided CSV' do
        importer = build_importer

        expect(importer.row_data).to be_kind_of CSV::Table
        expect(importer.row_data.count).to eq 100
      end
    end

    context 'with data that has invalid headers' do
      it 'returns the rows for the provided CSV' do
        importer = build_importer(path: invalid_headers_sample_data_path)
        required_headers_list = EmployeeCsvImporter::REQUIRED_HEADERS.join(', ')
        invalid_headers_list  = 'cn, givenName, sn, employeeNumber, relayGuid, thekeyGuid'

        message = "Your CSV file must have the headers: #{required_headers_list}, instead it has: #{invalid_headers_list}"

        expect { importer.row_data }
          .to raise_error(EmployeeCsvImporter::InvalidHeadersError)
          .with_message(message)
      end
    end
  end

  describe '.import' do
    it 'delegates to an instance of EmployeeCsvImporter' do
      instance = double('employee_csv_importer')

      allow(EmployeeCsvImporter)
        .to receive(:new)
        .with(path: sample_data_path)
        .and_return(instance)

      expect(instance).to receive(:import).with(from: 5, to: 10)

      EmployeeCsvImporter.import(
        path: sample_data_path,
        from: 5,
        to: 10
      )
    end
  end

  describe '.queue' do
    it 'delegates to an instance of EmployeeCsvImporter' do
      instance = double('employee_csv_importer')

      allow(EmployeeCsvImporter)
        .to receive(:new)
        .with(path: sample_data_path, import_group_size: 10)
        .and_return(instance)

      expect(instance).to receive(:queue!)

      EmployeeCsvImporter.queue(
        path: sample_data_path,
        import_group_size: 10
      )
    end
  end

  private

  def build_importer(path: nil, import_group_size: nil)
    path ||= sample_data_path
    EmployeeCsvImporter.new(path: path, import_group_size: import_group_size)
  end

  def sample_data_path
    Rails
      .root
      .join('spec/fixtures/employee_csv_importer/sample_employee_data.csv')
  end

  def invalid_headers_sample_data_path
    Rails
      .root
      .join('spec/fixtures/employee_csv_importer/invalid_headers_sample.csv')
  end
end
