require 'rails_helper'

RSpec.describe MailChimp::CampaignLogger do
  let(:mail_chimp_account) { create(:mail_chimp_account, auto_log_campaigns: true) }
  let(:account_list) { mail_chimp_account.account_list }

  let(:mock_gibbon) { double(:mock_gibbon) }
  let(:mock_gibbon_campaigns) { double(:mock_gibbon_campaigns) }

  subject { described_class.new(mail_chimp_account) }

  context '#log_sent_campaign' do
    before do
      allow(Gibbon::Request).to receive(:new).and_return(mock_gibbon)
      allow(mock_gibbon).to receive(:timeout)
      allow(mock_gibbon).to receive(:timeout=)
    end

    context 'auto_log_campaigns is false' do
      before do
        mail_chimp_account.update(auto_log_campaigns: false)
      end

      it 'should not log' do
        expect(subject).to_not receive(:log_sent_campaign!)
        subject.log_sent_campaign('Random_id', 'Random Subject')
      end
    end

    context 'error handling' do
      it 'handles case where campaign not completely sent' do
        expect(subject).to receive(:log_sent_campaign!).and_raise(Gibbon::MailChimpError, 'code 301')
        expect(mock_gibbon).to receive(:campaigns).with('Random_id').and_return(mock_gibbon_campaigns)
        expect(mock_gibbon_campaigns).to receive(:retrieve).and_return('send_time' => 30.minutes.ago.to_s)

        expect do
          subject.log_sent_campaign('Random_id', 'Random Subject')
        end.to raise_error LowerRetryWorker::RetryJobButNoRollbarError
      end

      it 'handles case where campaign has been running for more than one hour' do
        expect(subject).to receive(:log_sent_campaign!).and_raise(Gibbon::MailChimpError, 'code 301')
        expect(mock_gibbon).to receive(:campaigns).with('Random_id').and_return(mock_gibbon_campaigns)
        expect(mock_gibbon_campaigns).to receive(:retrieve).and_return('send_time' => 2.hours.ago.to_s)

        expect do
          subject.log_sent_campaign('Random_id', 'Random Subject')
        end.not_to raise_error
      end

      it 'handles all other errors by raising the Mail Chimp error' do
        allow(mock_gibbon).to receive(:campaigns).and_return(mock_gibbon_campaigns)
        allow(mock_gibbon_campaigns).to receive(:retrieve).and_return('send_time' => 2.hours.ago.to_s)

        expect(subject).to receive(:log_sent_campaign!).and_raise(Gibbon::MailChimpError)

        expect do
          subject.log_sent_campaign('Random_id', 'Random Subject')
        end.to raise_error Gibbon::MailChimpError
      end
    end

    context 'successful logging' do
      let(:sent_to_email) { 'email@gmail.com' }
      let!(:person) { create(:person, primary_email_address: build(:email_address, email: sent_to_email)) }
      let!(:contact) { create(:contact, account_list: account_list, primary_person: person) }

      let(:mock_gibbon_reports) { double(:mock_gibbon_reports) }
      let(:mock_gibbon_sent_to) { double(:mock_gibbon_sent_to) }

      let(:sent_to_reports) do
        {
          sent_to: [
            {
              email_address: sent_to_email
            }
          ]
        }
      end

      let(:logged_task) { Task.last }
      let(:send_time) { 30.minutes.ago.to_s }

      let(:mock_second_gibbon_campaigns) { double(:mock_second_gibbon_campaigns) }

      before do
        allow(mock_gibbon).to receive(:campaigns).with('random_campaign_id').and_return(mock_gibbon_campaigns)
        allow(mock_gibbon_campaigns).to receive(:retrieve).and_return('send_time' => send_time)

        allow(mock_gibbon).to receive(:campaigns).with('second_random_campaign_id').and_return(mock_second_gibbon_campaigns)
        allow(mock_second_gibbon_campaigns).to receive(:retrieve).and_return('send_time' => 2.days.ago.to_s)
      end

      before { travel_to(Time.local(2017, 1, 1, 12, 0, 0)) }
      after { travel_back }

      it 'logs the sent campaign' do
        expect(mock_gibbon).to receive(:reports).and_return(mock_gibbon_reports)
        expect(mock_gibbon_reports).to receive(:sent_to).and_return(mock_gibbon_sent_to)
        expect(mock_gibbon_sent_to).to receive(:retrieve).and_return(sent_to_reports)

        expect do
          subject.log_sent_campaign('random_campaign_id', 'Random Subject')
        end.to change { Task.count }.by(1)
        expect(logged_task.completed).to be_truthy
        expect(logged_task.start_at).to eq(send_time)
        expect(logged_task.completed_at).to eq(send_time)
        expect(logged_task.subject).to eq('MailChimp: Random Subject')
      end

      it 'does not log the same campaign more than once' do
        expect(mock_gibbon).to receive(:reports).and_return(mock_gibbon_reports)
        expect(mock_gibbon_reports).to receive(:sent_to).and_return(mock_gibbon_sent_to)
        expect(mock_gibbon_sent_to).to receive(:retrieve).and_return(sent_to_reports)

        expect { subject.log_sent_campaign('random_campaign_id', 'Random Subject') }.to change { Task.count }.by(1)

        expect(mock_gibbon).to receive(:reports).and_return(mock_gibbon_reports)
        expect(mock_gibbon_reports).to receive(:sent_to).and_return(mock_gibbon_sent_to)
        expect(mock_gibbon_sent_to).to receive(:retrieve).and_return(sent_to_reports)

        expect { subject.log_sent_campaign('random_campaign_id', 'Random Subject') }.to_not change { Task.count }
      end

      it 'does log two campaigns with the same subject but sent at different times' do
        expect(mock_gibbon).to receive(:reports).and_return(mock_gibbon_reports)
        expect(mock_gibbon_reports).to receive(:sent_to).and_return(mock_gibbon_sent_to)
        expect(mock_gibbon_sent_to).to receive(:retrieve).and_return(sent_to_reports)

        expect { subject.log_sent_campaign('random_campaign_id', 'Random Subject') }.to change { Task.count }.by(1)

        expect(mock_gibbon).to receive(:reports).and_return(mock_gibbon_reports)
        expect(mock_gibbon_reports).to receive(:sent_to).and_return(mock_gibbon_sent_to)
        expect(mock_gibbon_sent_to).to receive(:retrieve).and_return(sent_to_reports)

        expect { subject.log_sent_campaign('second_random_campaign_id', 'Random Subject') }.to change { Task.count }.by(1)
      end
    end
  end
end
