require 'rails_helper'

describe Person::GmailAccount do
  let(:google_account) { create(:google_account, last_email_sync: Date.today) }
  let(:gmail_account) { Person::GmailAccount.new(google_account) }
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:person) { create(:person) }
  let(:user) { create(:user) }

  context '#gmail' do
    it 'refreshes the google account token if expired' do
      google_account.expires_at = 1.hour.ago

      expect(google_account).to receive(:refresh_token!).once
      gmail_account.gmail {}
    end
  end

  context '#import_emails' do
    let(:recipient_data)    { double('recipient', mailbox: 'recipient', host: 'example.com') }
    let(:sender_data)       { double('sender', mailbox: 'sender', host: 'example.com') }
    let(:envelope)          { double('envelope', to: [recipient_data], sender: [sender_data]) }
    let(:gmail_uid)         { double('gmail_uid') }
    let(:gmail_imap_struct) { double('gmail_imap_struct', attr: { 'ENVELOPE' => envelope }) }

    let(:sent_mailbox) { double }
    let(:all_mailbox)  { double }
    let(:client_conn)  { double('client_connection') }

    let!(:recipient_email) { create(:email_address, email: 'recipient@example.com', person: person) }
    let!(:sender_email)    { create(:email_address, email: 'sender@example.com', person: person) }

    before do
      contact.people << person

      google_account.person = user
      google_account.save

      account_list.users << user

      allow_any_instance_of(Gmail::Client::XOAuth2).to receive(:mailbox).with('[Gmail]/Sent Mail').and_return(sent_mailbox)
      allow_any_instance_of(Gmail::Client::XOAuth2).to receive(:mailbox).with('[Gmail]/All Mail').and_return(all_mailbox)
      allow_any_instance_of(Gmail::Client::XOAuth2).to receive(:conn).and_return(client_conn)
      allow(client_conn).to receive(:uid_fetch).with([gmail_uid], kind_of(Array)).and_return([gmail_imap_struct])
      allow(client_conn).to receive(:uid_fetch).with([], kind_of(Array)).and_return([])
    end

    it 'logs a sent email' do
      expect(sent_mailbox).to  receive(:fetch_uids).with(on: google_account.last_email_sync.to_date).and_return([gmail_uid])
      expect(all_mailbox).to   receive(:fetch_uids).with(on: google_account.last_email_sync.to_date).and_return([])
      expect(gmail_account).to receive(:log_email).once

      gmail_account.import_emails(account_list)
    end

    it 'logs a received email' do
      expect(sent_mailbox).to  receive(:fetch_uids).with(on: google_account.last_email_sync.to_date).and_return([])
      expect(all_mailbox).to   receive(:fetch_uids).with(on: google_account.last_email_sync.to_date).and_return([gmail_uid])
      expect(gmail_account).to receive(:log_email).once

      gmail_account.import_emails(account_list)
    end

    it 'does not log a blacklisted received email' do
      expect(sent_mailbox).to  receive(:fetch_uids).with(on: google_account.last_email_sync.to_date).and_return([])
      expect(all_mailbox).to   receive(:fetch_uids).with(on: google_account.last_email_sync.to_date).and_return([gmail_uid])
      expect(gmail_account).to_not receive(:log_email)

      gmail_account.import_emails(account_list, [sender_email.email])
    end

    it 'does not log a blacklisted sent email' do
      expect(sent_mailbox).to  receive(:fetch_uids).with(on: google_account.last_email_sync.to_date).and_return([gmail_uid])
      expect(all_mailbox).to   receive(:fetch_uids).with(on: google_account.last_email_sync.to_date).and_return([])
      expect(gmail_account).to_not receive(:log_email)

      gmail_account.import_emails(account_list, [recipient_email.email])
    end
  end

  context '#log_email' do
    let(:gmail_message) { mock_gmail_message('message body') }
    let(:google_email)  { build(:google_email, google_email_id: gmail_message.msg_id, google_account: google_account) }

    def mock_gmail_message(body)
      double(message: double(multipart?: false, body: double(decoded: body)),
             envelope: double(date: Time.zone.now, message_id: '1'),
             subject: 'subject', msg_id: 1)
    end

    it 'creates a completed task' do
      expect do
        expect do
          gmail_account.log_email(gmail_message, account_list.id, contact.id, person.id, 'Done')
        end.to change(Task, :count).by(1)
      end.to change(ActivityComment, :count).by(1)

      task = Task.last

      expect(task.subject).to eq('subject')
      expect(task.completed).to eq(true)
      expect(task.completed_at.to_s(:db)).to eq(gmail_message.envelope.date.to_s(:db))
      expect(task.result).to eq('Done')
    end

    it "creates a task even if the email doesn't have a subject" do
      expect(gmail_message).to receive(:subject).and_return('')

      task = gmail_account.log_email(gmail_message, account_list.id, contact.id, person.id, 'Done')
      expect(task.subject).to eq('No Subject')
    end

    it 'truncates the subject if the subject is more than 2000 chars' do
      expect(gmail_message).to receive(:subject).once.and_return('x' * 2001)

      task = gmail_account.log_email(gmail_message, account_list.id, contact.id, person.id, 'Done')
      expect(task.subject).to eq('x' * 2000)
    end

    it "doesn't create a duplicate task" do
      google_email.save
      task = create(:task, account_list: account_list, remote_id: gmail_message.envelope.message_id, source: 'gmail')
      contact.tasks << task
      create(:google_email_activity, google_email: google_email, activity: task)

      expect do
        gmail_account.log_email(gmail_message, account_list.id, contact.id, person.id, 'Done')
      end.not_to change(Task, :count)
    end

    it 'creates a google_email' do
      expect do
        gmail_account.log_email(gmail_message, account_list.id, contact.id, person.id, 'Done')
      end.to change(GoogleEmail, :count).by(1)

      task = GoogleEmail.last
      expect(task.google_email_id).to eq(gmail_message.msg_id)
    end

    it "doesn't create a duplicate google_email" do
      google_email.save

      expect do
        gmail_account.log_email(gmail_message, account_list.id, contact.id, person.id, 'Done')
      end.not_to change(GoogleEmail, :count)
    end

    it 'handles messages with null bytes' do
      expect do
        gmail_account.log_email(mock_gmail_message("\0null\0!"), account_list.id, contact.id, person.id, 'Done')
      end.to change(Task, :count).by(1)

      expect(Task.last.comments.first.body).to eq 'null!'
    end
  end
end
