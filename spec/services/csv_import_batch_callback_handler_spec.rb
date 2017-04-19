require 'rails_helper'

describe CsvImportBatchCallbackHandler do
  let(:import) { create(:csv_import, in_preview: true) }
  let(:options) { { 'import_id' => import.id } }

  describe '#on_complete' do
    context 'no failures' do
      let(:status) { double(failures: 0) }

      it 'delegates handling to ImportCallbackHandler' do
        expect_any_instance_of(ImportCallbackHandler).to receive(:handle_success).once
        expect_any_instance_of(ImportCallbackHandler).to_not receive(:handle_failure).once
        expect_any_instance_of(ImportCallbackHandler).to receive(:handle_complete).once
        CsvImportBatchCallbackHandler.new.on_complete(status, options)
      end
    end

    context 'has failures' do
      let(:status) { double(failures: 1) }

      it 'delegates handling to ImportCallbackHandler' do
        expect_any_instance_of(ImportCallbackHandler).to receive(:handle_failure).once
        expect_any_instance_of(ImportCallbackHandler).to_not receive(:handle_success).once
        expect_any_instance_of(ImportCallbackHandler).to receive(:handle_complete).once
        CsvImportBatchCallbackHandler.new.on_complete(status, options)
      end
    end
  end
end
