RSpec.shared_examples 'after_validate_set_source_to_mpdx_examples' do |options = {}|
  describe 'after validate set source to MPDX' do
    let(:create_record) { create(options[:factory_type], source: 'TntImport') }
    let(:build_record) { build(options[:factory_type], source: 'TntImport') }

    it 'replaces MPDX with TntImport as source on validation' do
      record = create_record
      record.updated_at = Time.now.getlocal
      record.save!
      expect(record.source).to eq 'MPDX'
    end

    it 'does not set MPDX as source if validation is skipped' do
      record = create_record
      record.updated_at = Time.now.getlocal
      record.save!(validate: false)
      expect(record.source).to eq 'TntImport'
    end

    it 'does not set MPDX as source on create' do
      record = build_record
      record.updated_at = Time.now.getlocal
      record.save!(validate: false)
      expect(record.source).to eq 'TntImport'
    end
  end
end
