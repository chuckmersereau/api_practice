require 'rails_helper'

describe TntImport::HistoryImport do
  let(:account_list) { create(:account_list) }

  describe '#import_history' do
    context 'no xml history data' do
      it 'returns empty hash' do
        xml_double = double(tables: {})
        expect(TntImport::HistoryImport.new(account_list, {}, xml_double).import_history).to eq({})
      end
    end
  end
end
