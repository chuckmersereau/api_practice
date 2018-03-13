require 'rails_helper'

describe ImportCallbackHandler do
  let(:import) { create(:csv_import, in_preview: true) }

  before do
    Sidekiq::Testing.inline!
    import.update_column(:in_preview, false)
  end

  describe 'initialize' do
    it 'initializes' do
      expect(ImportCallbackHandler.new(import)).to be_a ImportCallbackHandler
    end
  end

  describe '#handle_start' do
    it 'updates import' do
      travel_to Time.current do
        expect { ImportCallbackHandler.new(import).handle_start }.to change { import.reload.importing }.from(false).to(true)
          .and change { import.import_started_at&.to_i }.from(nil).to(Time.current.to_i)
      end
    end
  end

  describe '#handle_success' do
    it 'runs after import success processes' do
      expect_any_instance_of(AccountList).to receive(:queue_sync_with_google_contacts).once
      expect_any_instance_of(AccountList).to receive(:valid_mail_chimp_account).and_return(true)
      expect_any_instance_of(AccountList).to receive(:mail_chimp_account).and_return(MailChimpAccount.new)
      expect(MailChimp::PrimaryListSyncWorker).to receive(:perform_async).once
      expect_delayed_email(ImportMailer, :success)
      ImportCallbackHandler.new(import).handle_success
    end

    it 'does not send an email if there is an error in the post import processes' do
      begin
        expect_any_instance_of(AccountList).to receive(:queue_sync_with_google_contacts).and_raise(StandardError)
        expect(ImportMailer).to_not receive(:delay)
        ImportCallbackHandler.new(import).handle_success
      rescue StandardError
      end
    end

    it 'sets the Import error to nil' do
      import.update_column(:error, 'ERROR')
      expect { ImportCallbackHandler.new(import).handle_success }.to change { import.reload.error }.from('ERROR').to(nil)
    end
  end

  describe '#handle_failure' do
    it 'sends import failure mail' do
      expect_delayed_email(ImportMailer, :failed)
      ImportCallbackHandler.new(import).handle_failure
    end

    it 'sets the Import error' do
      import.update_column(:error, nil)
      exception = StandardError.new('Just testing!')
      expect { ImportCallbackHandler.new(import).handle_failure(exception: exception) }.to change { import.reload.error }.from(nil).to('StandardError: Just testing!')
    end
  end

  describe '#handle_complete' do
    it 'runs after import complete processes' do
      import.update_column(:importing, true)
      expect_any_instance_of(AccountList).to receive(:async_merge_contacts).once
      expect(ContactSuggestedChangesUpdaterWorker).to receive(:perform_async)
      travel_to Time.current do
        expect { ImportCallbackHandler.new(import).handle_complete }.to change { import.reload.importing }.from(true).to(false)
          .and change { import.import_completed_at&.to_i }.from(nil).to(Time.current.to_i)
      end
    end

    it 'updates the record even if there is an error in the import complete processes' do
      travel_to Time.current do
        begin
          expect_any_instance_of(AccountList).to receive(:async_merge_contacts).and_raise(StandardError)
          expect { ImportCallbackHandler.new(import).handle_complete }.to change { import.reload.importing }.from(true).to(false)
            .and change { import.import_completed_at&.to_i }.from(nil).to(Time.current.to_i)
        rescue StandardError
        end
      end
    end
  end
end
