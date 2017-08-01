require 'rails_helper'

describe CsvFileConstantsMappingsFacade do
  let(:facade) { CsvFileConstantsMappingsFacade.new(file_constants_mappings) }

  shared_examples 'CsvFileConstantsMappingsFacade examples' do
    it 'initializes' do
      expect(CsvFileConstantsMappingsFacade.new({})).to be_a(CsvFileConstantsMappingsFacade)
    end

    describe '#header_ids' do
      it 'returns the header ids' do
        expect(facade.header_ids).to eq(%w(status commitment_frequency newsletter))
      end
    end

    describe '#convert_value' do
      it 'converts expected values' do
        expect(facade.convert_value('status', 'Praying and giving')).to eq('Partner - Financial')
        expect(facade.convert_value('status', '')).to eq('')
        expect(facade.convert_value('commitment_frequency', 'Monthly')).to eq('1.0')
        expect(facade.convert_value('commitment_frequency', '')).to eq(nil)
        expect(facade.convert_value('newsletter', 'Anything')).to eq('Both')
      end
    end

    describe '#find_unsupported_constants_for_header_id' do
      let(:file_constants_mappings) do
        {
          'status' => [
            { 'id' => 'Partner - Financial', 'values' => ['Praying and giving'] },
            { 'id' => 'What', 'values' => ['Just praying'] },
            { 'id' => '', 'values' => [''] }
          ],
          'commitment_frequency' => [
            { 'id' => '1.0', 'values' => ['Monthly'] },
            { 'id' => 'Annual', 'values' => ['Annual'] }
          ],
          'newsletter' => [
            { 'id' => 'Both', 'values' => %w(Both Anything) }
          ]
        }
      end

      it 'finds expected values that are unsupported' do
        expect(facade.find_unsupported_constants_for_header_id('status')).to eq(['What'])
        expect(facade.find_unsupported_constants_for_header_id('commitment_frequency')).to eq(['Annual'])
        expect(facade.find_unsupported_constants_for_header_id('newsletter')).to eq([])
      end
    end

    describe '#find_mapped_values_for_header_id' do
      it 'finds expected values that are mapped' do
        expect(facade.find_mapped_values_for_header_id('status')).to eq(['Praying and giving', 'Just praying', ''])
        expect(facade.find_mapped_values_for_header_id('commitment_frequency')).to eq(%w(Monthly Annual))
        expect(facade.find_mapped_values_for_header_id('newsletter')).to eq(%w(Both Anything))
      end
    end
  end

  context 'file_constants_mappings are key and value pairs' do
    let(:file_constants_mappings) do
      {
        'status' => {
          'partner_financial' => 'Praying and giving',
          'partner_prayer' => 'Just praying',
          '' => ''
        },
        'commitment_frequency' => {
          '1_0' => 'Monthly',
          '12_0' => 'Annual'
        },
        'newsletter' => {
          'both' => %w(Both Anything)
        }
      }
    end

    include_examples 'CsvFileConstantsMappingsFacade examples'
  end

  context 'file_constants_mappings are id and values hashes' do
    let(:file_constants_mappings) do
      {
        'status' => [
          { 'id' => 'Partner - Financial', 'values' => ['Praying and giving'] },
          { 'id' => 'Partner - Prayer', 'values' => ['Just praying'] },
          { 'id' => '', 'values' => [''] }
        ],
        'commitment_frequency' => [
          { 'id' => '1.0', 'values' => ['Monthly'] },
          { 'id' => '12.0', 'values' => ['Annual'] }
        ],
        'newsletter' => [
          { 'id' => 'Both', 'values' => %w(Both Anything) }
        ]
      }
    end

    include_examples 'CsvFileConstantsMappingsFacade examples'
  end
end
