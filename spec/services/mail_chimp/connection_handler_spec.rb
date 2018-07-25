require 'rails_helper'

RSpec.describe MailChimp::ConnectionHandler do
  let(:mail_chimp_account) { create(:mail_chimp_account, primary_list_id: 'List1', active: true) }
  subject { described_class.new(mail_chimp_account) }

  context '#call_mail_chimp' do
    let(:status_code) { 400 }
    let(:error_message) { 'Random Message' }
    let(:error) { Gibbon::MailChimpError.new(error_message, status_code: status_code, detail: error_message) }
    let(:mail_chimp_syncer) { MailChimp::Syncer.new(mail_chimp_account) }

    context 'API key disabled' do
      context '"API Key Disabled" message' do
        let(:error_message) { 'API Key Disabled' }

        it 'sets the mail chimp account to inactive and sends an email' do
          raise_error_on_two_way_sync
          expect_invalid_mailchimp_key_email

          expect do
            subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
          end.to change { mail_chimp_account.reload.active }
        end
      end

      context '"code 104" message' do
        let(:error_message) { 'code 104' }

        it 'sets the mail chimp account to inactive and sends an email' do
          raise_error_on_two_way_sync
          expect_invalid_mailchimp_key_email

          expect do
            subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
          end.to change { mail_chimp_account.reload.active }
        end
      end

      context 'Deactivated account' do
        let(:error_message) { 'This account has been deactivated.' }

        it 'sets the mail chimp account to inactive and sends an email' do
          raise_error_on_two_way_sync
          expect_invalid_mailchimp_key_email

          expect do
            subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
          end.to change { mail_chimp_account.reload.active }
        end
      end
    end

    context 'Invalid merge fields' do
      let(:error_message) { 'Your merge fields were invalid.' }

      it 'sets the mail chimp account primary_list_id to nil and sends an email' do
        raise_error_on_two_way_sync
        expect_email(:mailchimp_required_merge_field)

        expect do
          subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
        end.to change { mail_chimp_account.reload.primary_list_id }
      end
    end

    context 'Invalid mail chimp list' do
      let(:error_message) { 'code 200' }

      it 'removes the primary_list_id from the mail chimp account' do
        raise_error_on_two_way_sync

        expect do
          subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
        end.to change { mail_chimp_account.reload.primary_list_id }.to(nil)
      end
    end

    context 'Resource Not Found' do
      let(:error_message) { 'The requested resource could not be found.' }

      it 'removes the primary_list_id from the mail chimp account' do
        raise_error_on_two_way_sync
        lists_url = 'https://us4.api.mailchimp.com/3.0/lists?count=100'
        stub_request(:get, lists_url).to_return(body: { lists: [] }.to_json)

        expect do
          subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
        end.to change { mail_chimp_account.reload.primary_list_id }.to(nil)
      end
    end

    context 'Invalid email' do
      let(:error_message) { 'looks fake or invalid, please enter a real email' }

      it 'ignores the error silently' do
        raise_error_on_two_way_sync

        expect do
          subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
        end.to_not raise_error
      end
    end

    context 'Email already subscribed' do
      let(:error_message) { 'code 214' }

      it 'ignores the error silently' do
        raise_error_on_two_way_sync

        expect do
          subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
        end.to_not raise_error
      end
    end

    context 'Mail Chimp Server Errors' do
      context 'Server temporarily unavailable' do
        let(:status_code) { '503' }

        it 'raises an error to silently retry job' do
          raise_error_on_two_way_sync

          expect do
            subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
          end.to raise_error(LowerRetryWorker::RetryJobButNoRollbarError)
        end
      end

      context 'Number of connections limit reached' do
        let(:status_code) { '429' }

        it 'raises an error to silently retry job' do
          raise_error_on_two_way_sync

          expect do
            subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
          end.to raise_error(LowerRetryWorker::RetryJobButNoRollbarError)
        end
      end

      context 'All other cases' do
        it 'raises the error' do
          raise_error_on_two_way_sync

          expect do
            subject.call_mail_chimp(mail_chimp_syncer, :two_way_sync_with_primary_list)
          end.to raise_error(error)
        end
      end
    end

    def expect_invalid_mailchimp_key_email
      expect_email(:invalid_mailchimp_key)
    end

    def raise_error_on_two_way_sync
      expect(mail_chimp_syncer).to receive(:two_way_sync_with_primary_list!).and_raise(error)
    end

    def expect_email(mailer_method)
      delayed = double
      expect(AccountMailer).to receive(:delay).and_return(delayed)
      expect(delayed).to receive(mailer_method)
    end
  end
end
