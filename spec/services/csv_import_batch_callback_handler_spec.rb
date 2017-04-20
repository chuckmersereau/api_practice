require 'rails_helper'

describe CsvImportBatchCallbackHandler do
  let(:import) { create(:csv_import, file_row_failures: [], in_preview: true) }
  let(:options) { { 'import_id' => import.id } }
  let(:status) { double(total: 100) }

  describe '#on_complete' do
    context 'no failures' do
      it 'delegates handling to ImportCallbackHandler' do
        expect_any_instance_of(ImportCallbackHandler).to receive(:handle_success).once
        expect_any_instance_of(ImportCallbackHandler).to_not receive(:handle_failure).once
        expect_any_instance_of(ImportCallbackHandler).to receive(:handle_complete).once
        CsvImportBatchCallbackHandler.new.on_complete(status, options)
      end
    end

    context 'has failures' do
      before do
        import.update_column(:file_row_failures, [1, 2, 3])
      end

      it 'delegates handling to ImportCallbackHandler' do
        expect_any_instance_of(ImportCallbackHandler).to receive(:handle_failure).once
        expect_any_instance_of(ImportCallbackHandler).to_not receive(:handle_success).once
        expect_any_instance_of(ImportCallbackHandler).to receive(:handle_complete).once
        CsvImportBatchCallbackHandler.new.on_complete(status, options)
      end
    end
  end
end
