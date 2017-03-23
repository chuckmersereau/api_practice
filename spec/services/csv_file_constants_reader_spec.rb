require 'rails_helper'

describe CsvFileConstantsReader do
  let(:file_path) { Rails.root.join('spec/fixtures/sample_csv_with_custom_headers.csv') }
  let(:service) { CsvFileConstantsReader.new(File.open(file_path).read) }

  it 'initializes' do
    expect(service).to be_a CsvFileConstantsReader
  end

  describe '#constants' do
    it 'returns a correct hash of sets' do
      expect(service.constants).to eq(
        'greeting' => Set.new(['Hi John and Jane', 'Hello!', nil]),
        'status' => Set.new(['Praying', 'Praying and giving']),
        'amount' => Set.new(['50', '10', nil]),
        'frequency' => Set.new(['Monthly', nil]),
        'newsletter' => Set.new(['Both']),
        'currency' => Set.new(['CAD', nil]),
        'skip' => Set.new(['No', 'Yes', nil]),
        'appeals' => Set.new(%w(Yes No)),
        'likely-giver' => Set.new(%w(Yes No))
      )
    end
  end
end
