require 'rails_helper'

describe CsvImportMappingsValidator do
  INVALID_STATUS = 'has an invalid mapping. For the header "status", we '\
                   "couldn't find the following values in the CSV".freeze
  MISSING_STATUS = "is missing mappings. For the header \"status\", we couldn't find the following "\
                   'mappings to the CSV values: ["Praying", "Praying and giving"]'.freeze

  let!(:import) { create(:csv_import_custom_headers, in_preview: true) }

  before do
    CsvImport.new(import).update_cached_file_data
    import.in_preview = false
  end

  it 'validates that file_headers_mappings_contains_required_headers' do
    expected_error = 'should specify a header mapping for at least one of the required headers'
    expect(CsvImport).to receive(:required_headers).and_return('first_name' => 'First Name').at_least(:once)

    import.file_headers_mappings = { 'something_invalid' => 'fname' }
    expect(import.valid?).to eq false
    expect(import.errors[:file_headers_mappings].any? { |error| error.starts_with?(expected_error) }).to eq true

    import.file_headers_mappings = { 'first_name' => 'fname' }
    import.valid?
    expect(import.errors[:file_headers_mappings].any? { |error| error.starts_with?(expected_error) }).to eq false
  end

  it 'validates that file_headers_mappings_contains_only_supported_headers' do
    expected_error = 'has unsupported headers. One or more of the headers '\
                     'specified in file_headers_mappings is not supported'

    import.file_headers_mappings = { 'something_invalid' => 'fname' }
    expect(import.valid?).to eq false

    expect(import.errors[:file_headers_mappings].any? { |error| error.starts_with?(expected_error) }).to eq true

    import.file_headers_mappings = { 'first_name' => 'fname' }
    import.valid?

    expect(import.errors[:file_headers_mappings].any? { |error| error.starts_with?(expected_error) }).to eq false
  end

  it 'validates that file_headers_mappings_only_maps_to_headers_in_the_file' do
    expected_error = 'has unsupported mappings. One or more of the header mappings '\
                     'was not found in the headers of the given CSV file'
    import.file_headers_mappings = { 'first_name' => 'something invalid' }
    expect(import.valid?).to eq false
    expect(import.errors[:file_headers_mappings].any? { |error| error.starts_with?(expected_error) }).to eq true

    import.file_headers_mappings = { 'first_name' => 'fname' }
    import.valid?
    expect(import.errors[:file_headers_mappings].any? { |error| error.starts_with?(expected_error) }).to eq false
  end

  context 'mappings have the format of key and value pairs' do
    it 'validates that file_constants_mappings_contains_the_constants_needed_for_import' do
      expected_error = 'is missing mappings. One or more of the header constants specified in '\
                       'file_headers_mappings does not have a mapping specified in file_constants_mappings'
      import.file_headers_mappings = {
        'first_name' => 'fname',
        'status' => 'status'
      }
      import.file_constants_mappings = {}
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? { |error| error.starts_with?(expected_error) }).to eq true

      import.file_constants_mappings = { 'status' => [] }
      import.valid?
      expect(import.errors[:file_constants_mappings].any? { |error| error.starts_with?(expected_error) }).to eq false
    end

    it 'validates that file_constants_mappings_only_maps_constants_that_are_supported' do
      import.file_headers_mappings = {
        'first_name' => 'fname',
        'status' => 'status'
      }
      import.file_constants_mappings = {
        'status' => [{
          id: 'Something Invalid',
          values: ['Praying and giving']
        }]
      }
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?('has an invalid mapping. For the header "status", you cannot map to the constants')
      end).to eq true

      import.file_constants_mappings = {
        'status' => [{
          id: 'Partner - Financial',
          values: ['Praying and giving']
        }]
      }
      import.valid?
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?('has an invalid mapping. For the header "status", you cannot map to the constants')
      end).to eq false
    end

    it 'validates that file_constants_mappings_only_maps_constants_that_are_also_in_file_headers_mappings' do
      expected_error = 'has an invalid mapping. You cannot map to the constants ["status"] '\
                       'because they are not found in file_headers_mappings'
      import.file_headers_mappings = {
        'first_name' => 'fname'
      }
      import.file_constants_mappings = {
        'status' => [{
          id: 'Partner - Financial',
          values: ['Praying and giving']
        }]
      }
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? { |error| error.starts_with?(expected_error) }).to eq true

      import.file_headers_mappings['Status'] = 'status'
      import.valid?
      expect(import.errors[:file_constants_mappings].any? { |error| error.starts_with?(expected_error) }).to eq false
    end

    it 'validates that file_constants_mappings_only_maps_constants_to_values_found_in_the_csv' do
      import.file_headers_mappings = {
        'first_name' => 'fname',
        'status' => 'status'
      }
      import.file_constants_mappings = {
        'status' => [{
          id: 'Partner - Financial',
          values: ['something invalid']
        }]
      }
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? { |error| error.starts_with?(INVALID_STATUS) }).to eq true

      import.file_constants_mappings = {
        'status' => [{
          id: 'Partner - Financial',
          values: ['Praying and giving']
        }]
      }
      import.valid?
      expect(import.errors[:file_constants_mappings].any? { |error| error.starts_with?(INVALID_STATUS) }).to eq false
    end

    it 'validates that file_constants_mappings_maps_all_constants_values_found_in_the_csv' do
      import.file_headers_mappings = {
        'first_name' => 'fname',
        'status' => 'status'
      }
      import.file_constants_mappings = {
        'status' => []
      }
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(MISSING_STATUS)
      end).to eq true

      import.file_constants_mappings = {
        'status' => [
          {
            id: 'Partner - Financial',
            values: ['Praying and giving']
          },
          {
            id: 'Partner - Prayer',
            values: ['Praying']
          }
        ]
      }
      import.valid?
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(MISSING_STATUS)
      end).to eq false
    end
  end

  context 'mappings have the format of id and values hashes' do
    it 'validates that file_constants_mappings_contains_the_constants_needed_for_import' do
      missing_const = 'is missing mappings. One or more of the header constants specified in '\
                      'file_headers_mappings does not have a mapping specified in file_constants_mappings'
      import.file_headers_mappings = {
        'first_name' => 'fname',
        'status' => 'status'
      }
      import.file_constants_mappings = {}
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(missing_const)
      end).to eq true

      import.file_constants_mappings = {
        'status' => []
      }
      import.valid?
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(missing_const)
      end).to eq false
    end

    it 'validates that file_constants_mappings_only_maps_constants_that_are_supported' do
      import.file_headers_mappings = {
        'first_name' => 'fname',
        'status' => 'status'
      }
      import.file_constants_mappings = {
        'status' => [{
          id: 'Something Invalid',
          values: ['Praying and giving']
        }]
      }
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?('has an invalid mapping. For the header "status", you cannot map to the constants')
      end).to eq true

      import.file_constants_mappings = {
        'status' => [{
          id: 'Partner - Financial',
          values: ['Praying and giving']
        }]
      }
      import.valid?
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?('has an invalid mapping. For the header "status", you cannot map to the constants')
      end).to eq false
    end

    it 'validates that file_constants_mappings_only_maps_constants_that_are_also_in_file_headers_mappings' do
      invalid_const_map = 'has an invalid mapping. You cannot map to the constants '\
                          '["status"] because they are not found in file_headers_mappings'
      import.file_headers_mappings = {
        'first_name' => 'fname'
      }
      import.file_constants_mappings = {
        'status' => [{
          id: 'Partner - Financial',
          values: ['Praying and giving']
        }]
      }
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(invalid_const_map)
      end).to eq true

      import.file_headers_mappings['Status'] = 'status'
      import.valid?
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(invalid_const_map)
      end).to eq false
    end

    it 'validates that file_constants_mappings_only_maps_constants_to_values_found_in_the_csv' do
      import.file_headers_mappings = {
        'first_name' => 'fname',
        'status' => 'status'
      }
      import.file_constants_mappings = {
        'status' => [{
          id: 'Partner - Financial',
          values: ['something invalid']
        }]
      }
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(INVALID_STATUS)
      end).to eq true

      import.file_constants_mappings = {
        'status' => [{
          id: 'Partner - Financial',
          values: ['Praying and giving']
        }]
      }
      import.valid?
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(INVALID_STATUS)
      end).to eq false
    end

    it 'validates that file_constants_mappings_maps_all_constants_values_found_in_the_csv' do
      import.file_headers_mappings = {
        'first_name' => 'fname',
        'status' => 'status'
      }
      import.file_constants_mappings = {
        'status' => []
      }
      expect(import.valid?).to eq false
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(MISSING_STATUS)
      end).to eq true

      import.file_constants_mappings = {
        'status' => [
          {
            id: 'Partner - Financial',
            values: ['Praying and giving']
          },
          {
            id: 'Partner - Prayer',
            values: ['Praying']
          }
        ]
      }
      import.valid?
      expect(import.errors[:file_constants_mappings].any? do |error|
        error.starts_with?(MISSING_STATUS)
      end).to eq false
    end
  end
end
