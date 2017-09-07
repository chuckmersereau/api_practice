require 'rails_helper'

describe TntImport::TasksImport do
  let(:user) { create(:user) }
  let(:tnt_import) { create(:tnt_import, override: true, user: user) }
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }

  before do
    stub_smarty_streets
  end

  describe '#import' do
    context 'no xml task data' do
      it 'returns empty hash' do
        xml_double = double(tables: {})
        expect(TntImport::TasksImport.new(tnt_import, {}, xml_double).import).to eq(nil)
      end
    end

    context 'with data change task types' do
      before do
        xml.tables['Task'].first['TaskTypeID'] = '190'
      end

      it 'skips change data task items' do
        expect { TntImport::TasksImport.new(tnt_import, {}, xml).import }.to_not change { Task.count }
      end
    end
  end
end
