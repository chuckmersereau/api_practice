require 'rails_helper'

describe TntImport::HistoryImport do
  let(:user) { create(:user) }
  let(:tnt_import) { create(:tnt_import, override: true, user: user) }
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }

  before do
    stub_smarty_streets
  end

  describe '#import_history' do
    context 'no xml history data' do
      it 'returns empty hash' do
        xml_double = double(tables: {})
        expect(TntImport::HistoryImport.new(tnt_import, {}, xml_double).import_history).to eq({})
      end
    end

    context 'with data change task types' do
      before do
        xml.tables['History'].first['TaskTypeID'] = '190'
      end

      it 'skips change data history items' do
        expect { TntImport::HistoryImport.new(tnt_import, {}, xml).import_history }.to_not change { Task.count }
      end
    end
  end
end
