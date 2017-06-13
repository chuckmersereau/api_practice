require 'rails_helper'

describe TntImport::HistoryImport do
  let(:import) { create(:tnt_import, override: true) }

  describe '#import_history' do
    context 'no xml history data' do
      it 'returns empty hash' do
        xml_double = double(tables: {})
        expect(TntImport::HistoryImport.new(import, {}, xml_double).import_history).to eq({})
      end
    end
  end
end
