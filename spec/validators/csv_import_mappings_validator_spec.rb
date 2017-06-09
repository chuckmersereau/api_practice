require 'rails_helper'

describe CsvImportMappingsValidator do
  let!(:import) { create(:csv_import_custom_headers, in_preview: true) }

  before do
    CsvImport.new(import).update_cached_file_data
    import.in_preview = false
  end

  it 'validates that file_headers_mappings_contains_required_headers' do
    expect(CsvImport).to receive(:required_headers).and_return('first_name' => 'First Name').at_least(:once)

    import.file_headers_mappings = { 'something_invalid' => 'fname' }
    expect(import.valid?).to eq false
    expect(import.errors[:file_headers_mappings].any? { |error| error.starts_with?('should specify a header mapping for at least one of the required headers') }).to eq true

    import.file_headers_mappings = { 'first_name' => 'fname' }
    import.valid?
    expect(import.errors[:file_headers_mappings].any? { |error| error.starts_with?('should specify a header mapping for at least one of the required headers') }).to eq false
  end

  it 'validates that file_headers_mappings_contains_only_supported_headers' do
    import.file_headers_mappings = { 'something_invalid' => 'fname' }
    expect(import.valid?).to eq false
    expect(import.errors[:file_headers_mappings].any? do |error|
      error.starts_with?('has unsupported headers. One or more of the headers specified in file_headers_mappings is not supported')
    end).to eq true

    import.file_headers_mappings = { 'first_name' => 'fname' }
    import.valid?
    expect(import.errors[:file_headers_mappings].any? do |error|
      error.starts_with?('has unsupported headers. One or more of the headers specified in file_headers_mappings is not supported')
    end).to eq false
  end

  it 'validates that file_headers_mappings_only_maps_to_headers_in_the_file' do
    import.file_headers_mappings = { 'first_name' => 'something invalid' }
    expect(import.valid?).to eq false
    expect(import.errors[:file_headers_mappings].any? do |error|
      error.starts_with?('has unsupported mappings. One or more of the header mappings was not found in the headers of the given CSV file')
    end).to eq true

    import.file_headers_mappings = { 'first_name' => 'fname' }
    import.valid?
    expect(import.errors[:file_headers_mappings].any? do |error|
      error.starts_with?('has unsupported mappings. One or more of the header mappings was not found in the headers of the given CSV file')
    end).to eq false
  end

  it 'validates that file_constants_mappings_contains_the_constants_needed_for_import' do
    import.file_headers_mappings = {
      'first_name' => 'fname',
      'status' => 'status'
    }
    import.file_constants_mappings = {}
    expect(import.valid?).to eq false
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?('is missing mappings. One or more of the header constants specified in file_headers_mappings does not have a mapping specified in file_constants_mappings')
    end).to eq true

    import.file_constants_mappings = { 'status' => {} }
    import.valid?
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?('is missing mappings. One or more of the header constants specified in file_headers_mappings does not have a mapping specified in file_constants_mappings')
    end).to eq false
  end

  it 'validates that file_constants_mappings_only_maps_constants_that_are_supported' do
    import.file_headers_mappings = {
      'first_name' => 'fname',
      'status' => 'status'
    }
    import.file_constants_mappings = {
      'status' => {
        'something_invalid' => 'Praying and giving'
      }
    }
    expect(import.valid?).to eq false
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?('has an invalid mapping. For the header "status", you cannot map to the constants')
    end).to eq true

    import.file_constants_mappings = {
      'status' => {
        'partner_financial' => 'Praying and giving'
      }
    }
    import.valid?
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?('has an invalid mapping. For the header "status", you cannot map to the constants')
    end).to eq false
  end

  it 'validates that file_constants_mappings_only_maps_constants_that_are_also_in_file_headers_mappings' do
    import.file_headers_mappings = {
      'first_name' => 'fname'
    }
    import.file_constants_mappings = {
      'status' => {
        'partner_financial' => 'Praying and giving'
      }
    }
    expect(import.valid?).to eq false
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?('has an invalid mapping. You cannot map to the constants ["status"] because they are not found in file_headers_mappings')
    end).to eq true

    import.file_headers_mappings['Status'] = 'status'
    import.valid?
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?('has an invalid mapping. You cannot map to the constants ["status"] because they are not found in file_headers_mappings')
    end).to eq false
  end

  it 'validates that file_constants_mappings_only_maps_constants_to_values_found_in_the_csv' do
    import.file_headers_mappings = {
      'first_name' => 'fname',
      'status' => 'status'
    }
    import.file_constants_mappings = {
      'status' => {
        'partner_financial' => 'something invalid'
      }
    }
    expect(import.valid?).to eq false
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?(%(has an invalid mapping. For the header "status", we couldn't find the following values in the CSV))
    end).to eq true

    import.file_constants_mappings = {
      'status' => {
        'partner_financial' => 'Praying and giving'
      }
    }
    import.valid?
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?(%(has an invalid mapping. For the header "status", we couldn't find the following values in the CSV))
    end).to eq false
  end

  it 'validates that file_constants_mappings_maps_all_constants_values_found_in_the_csv' do
    import.file_headers_mappings = {
      'first_name' => 'fname',
      'status' => 'status'
    }
    import.file_constants_mappings = {
      'status' => {}
    }
    expect(import.valid?).to eq false
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?(%(is missing mappings. For the header "status", we couldn't find the following mappings to the CSV values: ["Praying", "Praying and giving"]))
    end).to eq true

    import.file_constants_mappings = {
      'status' => {
        'partner_financial' => 'Praying and giving',
        'partner_prayer' => 'Praying'
      }
    }
    import.valid?
    expect(import.errors[:file_constants_mappings].any? do |error|
      error.starts_with?(%(is missing mappings. For the header "status", we couldn't find the following mappings to the CSV values: ["Praying", "Praying and giving"]))
    end).to eq false
  end
end
