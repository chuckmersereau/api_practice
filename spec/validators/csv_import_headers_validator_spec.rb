require 'spec_helper'

describe CsvImportHeadersValidator do
  let(:import) { build(:csv_import) }

  it 'is invalid if there are no headers' do
    expect_headers_valid([], false)
  end

  it 'is invalid if there are missing required headers' do
    expect_headers_valid(['Spouse First Name'], false)
  end

  it 'is invalid if an extra header is present' do
    expect_headers_valid(CsvImport::SUPPORTED_HEADERS + ['Extra header!'], false)
  end

  it 'is valid if the required headers are present' do
    expect_headers_valid(CsvImport::REQUIRED_HEADERS, true)
  end

  it 'does not error if the file is nil' do
    expect(import).to receive(:file).at_least(:once).and_return(nil)
    expect { import.valid? }.to_not raise_error
  end

  def expect_headers_valid(headers, valid)
    expect(import).to receive(:file_contents).and_return(headers.join(','))
    expect(import.valid?).to eq(valid)
    expect(import.errors.empty?).to eq(valid)
  end
end
