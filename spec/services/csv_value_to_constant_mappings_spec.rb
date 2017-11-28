require 'rails_helper'

describe CsvValueToConstantMappings do
  let(:file_constants_mappings) do
    {
      'status' => [
        { 'id' => 'Partner - Financial', 'values' => ['Praying and giving'] },
        { 'id' => 'What', 'values' => ['Just praying'] },
        { 'id' => '', 'values' => [''] }
      ],
      'pledge_frequency' => [
        { 'id' => 'Monthly', 'values' => ['Monthly'] },
        { 'id' => '12.0', 'values' => ['Annual'] }
      ],
      'newsletter' => [
        { 'id' => 'Both', 'values' => %w(Both Anything) }
      ]
    }
  end

  subject { described_class.new(file_constants_mappings) }

  it 'initializes' do
    expect(described_class.new({})).to be_a(described_class)
  end

  describe '#constant_names' do
    it 'returns the header ids' do
      expect(subject.constant_names).to eq(%w(status pledge_frequency newsletter))
    end
  end

  describe '#convert_value' do
    it 'converts expected values' do
      expect(subject.convert_value_to_constant_id('status', 'Praying and giving')).to eq('Partner - Financial')
      expect(subject.convert_value_to_constant_id('status', '')).to eq(nil)
      expect(subject.convert_value_to_constant_id('pledge_frequency', 'Monthly')).to eq(1.0)
      expect(subject.convert_value_to_constant_id('pledge_frequency', '')).to eq(nil)
      expect(subject.convert_value_to_constant_id('newsletter', 'Anything')).to eq('Both')
    end
  end

  describe '#find_unsupported_constants' do
    it 'finds expected values that are unsupported' do
      expect(subject.find_unsupported_constants('status')).to eq(['What'])
      expect(subject.find_unsupported_constants('pledge_frequency')).to eq(['12.0'])
      expect(subject.find_unsupported_constants('newsletter')).to eq([])
    end
  end

  describe '#find_mapped_values' do
    it 'finds expected values that are mapped' do
      expect(subject.find_mapped_values('status')).to eq(['Praying and giving', 'Just praying', ''])
      expect(subject.find_mapped_values('pledge_frequency')).to eq(%w(Monthly Annual))
      expect(subject.find_mapped_values('newsletter')).to eq(%w(Both Anything))
    end
  end
end
