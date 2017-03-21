RSpec.shared_examples 'before_create_set_valid_values_based_on_source_examples' do |options = {}|
  describe 'before create set valid_values based on source' do
    let(:built) { build(options[:factory_type]) }

    it 'sets valid false if source is not MPDX' do
      record = built
      record.source = 'unknown'
      record.save!
      expect(record.valid_values).to eq false
      expect(record.source).to eq 'unknown'
    end

    it 'sets valid true if source is MPDX' do
      record = built
      record.source = 'MPDX'
      record.save!
      expect(record.valid_values).to eq true
      expect(record.source).to eq 'MPDX'
    end

    it 'sets valid true if source is not specified' do
      record = described_class.create!(built.attributes.except(:source))
      expect(record.valid_values).to eq true
      expect(record.source).to eq 'MPDX'
    end
  end
end
