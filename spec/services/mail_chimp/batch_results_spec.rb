require 'rails_helper'

RSpec.describe MailChimp::BatchResults do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:mail_chimp_account) { create(:mail_chimp_account, active: true, account_list: account_list) }

  let(:mock_gibbon) { double(:mock_gibbon) }
  let(:mock_gibbon_batches) { double(:mock_gibbon_batches) }

  let(:batch_id) { 'asdf_batch_id' }
  let(:invalid_email) { 'bill@facebook.com' }

  subject { described_class.new(mail_chimp_account) }

  context '#check_batch' do
    before do
      allow(Gibbon::Request).to receive(:new).and_return(mock_gibbon)
      allow(mock_gibbon).to receive(:timeout)
      allow(mock_gibbon).to receive(:timeout=)
      allow(mock_gibbon).to receive(:batches).with(batch_id).and_return(mock_gibbon_batches)
    end

    context 'finished batch' do
      before do
        failed_batch_fixture = 'spec/fixtures/failed_mc_batch.tar.gz'
        allow(mock_gibbon_batches).to receive(:retrieve).and_return('status' => 'finished',
                                                                    'errored_operations' => 1,
                                                                    'response_body_url' => failed_batch_fixture)
      end

      context 'two contacts with invalid emails' do
        let!(:contact1) do
          create(:contact_with_person, account_list: account_list).tap do |c|
            c.primary_person.update(email: invalid_email)
          end
        end
        let!(:contact2) do
          create(:contact_with_person, account_list: account_list).tap do |c|
            c.primary_person.update(email: invalid_email)
          end
        end

        it 'mark emails as historic' do
          subject.check_batch(batch_id)

          expect(contact1.primary_person.email_addresses.find_by(email: invalid_email)).to be_historic
          expect(contact2.primary_person.email_addresses.find_by(email: invalid_email)).to be_historic
        end

        it 'marks second emails as primary' do
          contact1.primary_person.email_addresses.create(email: 'secondary@email.com')
          contact1.primary_person.email_addresses.find_by(email: invalid_email).update(primary: true)

          expect { subject.check_batch(batch_id) }.to change { contact1.primary_person.reload.email }
        end

        it 'do not update email address if it is not primary' do
          contact1.primary_person.update(email: 'secondary@email.com')

          subject.check_batch(batch_id)

          expect(contact1.primary_person.email_addresses.find_by(email: invalid_email)).to_not be_historic
          expect(contact2.primary_person.email_addresses.find_by(email: invalid_email)).to be_historic
        end

        it 'sends an email to users on account list' do
          account_list.users << create(:user)
          expect { subject.check_batch(batch_id) }.to change { Sidekiq::Extensions::DelayedMailer.jobs.size }.by(2)
        end
      end

      context 'compliance error' do
        let!(:contact) do
          create(:contact_with_person, account_list: account_list).tap do |c|
            c.primary_person.update(email: invalid_email)
          end
        end

        before do
          mock_json = [
            {
              'status_code' => 400,
              'operation_id' => nil,
              'response' => "{\"status\":400,\"detail\":\"#{invalid_email} is in a compliance state "\
                             'due to unsubscribe, bounce, or compliance review and cannot be subscribed."}'
            }
          ]
          allow(subject).to receive(:load_batch_json).and_return(mock_json)

          member_info = [{ 'status' => 'cleaned' }]
          allow(subject.send(:wrapper)).to receive(:list_member_info).and_return(member_info)
        end

        it 'sends an email to users on account list' do
          expect { subject.check_batch(batch_id) }.to change { Sidekiq::Extensions::DelayedMailer.jobs.size }.by(1)
        end
      end

      context 'unknown error' do
        let!(:contact) do
          create(:contact_with_person, account_list: account_list).tap do |c|
            c.primary_person.update(email: invalid_email)
          end
        end

        before do
          mock_json = [
            {
              'status_code' => 400,
              'operation_id' => nil,
              'response' => '{"status":400,"detail":"Some un-expected error from MailChimp"}'
            }
          ]
          allow(subject).to receive(:load_batch_json).and_return(mock_json)
        end

        it 'notifies Rollbar' do
          expect(Rollbar).to receive(:info)

          subject.check_batch(batch_id)
        end
      end

      context '404 error' do
        before do
          allow(mock_gibbon_batches).to receive(:retrieve).and_return('status' => 'finished',
                                                                      'errored_operations' => 1,
                                                                      'response_body_url' => 'url')
          not_found_response = [
            {
              "status_code": 404,
              "operation_id": nil,
              "response": '{"type":"http://developer.mailchimp.com/documentation/mailchimp/guides/error-glossary/",'\
                          '"title":"Resource Not Found","status":404,'\
                          '"detail":"The requested resource could not be found.","instance":""}'
            }
          ].to_json
          allow(subject).to receive(:read_first_file_from_tar).and_return(not_found_response)
        end

        it 'does not send an email' do
          expect { subject.check_batch(batch_id) }.to_not change { Sidekiq::Extensions::DelayedMailer.jobs.size }
        end
      end

      context 'no failures' do
        before do
          allow(mock_gibbon_batches).to receive(:retrieve).and_return('status' => 'finished', 'errored_operations' => 0)
        end

        it 'does not try to load the zip file' do
          expect(subject).to_not receive(:read_first_file_from_tar)

          subject.check_batch(batch_id)
        end
      end
    end

    context 'pending batch' do
      before do
        allow(mock_gibbon_batches).to receive(:retrieve).and_return('status' => 'pending')
      end

      it 'should retry' do
        expect { subject.check_batch(batch_id) }.to raise_error LowerRetryWorker::RetryJobButNoRollbarError
      end
    end
  end
end
