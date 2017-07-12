require 'rails_helper'

describe TntImport::Xml do
  let(:tnt_import) { create(:tnt_import, override: true) }
  let(:xml_reader) { TntImport::XmlReader.new(tnt_import) }

  describe 'initialize' do
    it 'initializes' do
      expect(xml_reader).to be_a TntImport::XmlReader
    end
  end

  describe '#parsed_xml' do
    context 'unparsable characters' do
      let(:test_file_path) { Rails.root.join('spec/fixtures/tnt/tnt_unparsable_characters.xml') }
      let(:tnt_import) { create(:tnt_import, override: true, file: File.new(test_file_path)) }

      it 'verify that the test file has unparsable characters' do
        contents = File.open(test_file_path).read
        expect(TntImport::XmlReader::UNPARSABLE_UTF8_CHARACTERS).to be_present
        expect(TntImport::XmlReader::UNPARSABLE_UTF8_CHARACTERS.all? do |unparsable_utf8_character|
          contents.include?(unparsable_utf8_character)
        end).to eq(true)
      end

      it 'handles unparsable utf8 characters' do
        # If the xml is not parsed properly we expect the number of returned tables to be less than 21
        expect(xml_reader.parsed_xml.tables.keys.size).to eq(21)
      end
    end
  end
end
