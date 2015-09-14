require 'spec_helper'

describe Person::GmailAccount do
  let(:google_account) { create(:google_account) }
  let(:gmail_account) { Person::GmailAccount.new(google_account) }
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:person) { create(:person) }
  let(:user) { create(:user) }
  let(:client) { double }

  context '#client' do
    it 'initializes a gmail client' do
      client = gmail_account.client
      expect(client.authorization.access_token).to eq(google_account.token)
    end
  end

  context '#folders' do
    it 'returns a list of gmail folders/labels' do
      allow(gmail_account).to receive(:client).and_return(client)

      expect(client).to receive(:labels).and_return(double(all: []))

      gmail_account.folders
    end
  end

  context '#gmail' do
    it 'refreshes the google account token if expired' do
      allow(Gmail).to receive(:connect).and_return(double(logout: true))
      google_account.expires_at = 1.hour.ago

      expect(google_account).to receive(:refresh_token!).once
      gmail_account.gmail {}
    end
  end

  context '#import_emails' do
    let(:sent_mailbox) { double }
    let(:all_mailbox) { double }
    let(:client) { double(logout: true) }
    let(:email) { double }
    let!(:email_address) { create(:email_address, person: person) }

    before do
      contact.people << person
      google_account.person = user
      google_account.save
      account_list.users << user

      allow(Gmail).to receive(:connect).and_return(client)
      allow(client).to receive(:mailbox).with('[Gmail]/Sent Mail').and_return(sent_mailbox)
      allow(client).to receive(:mailbox).with('[Gmail]/All Mail').and_return(all_mailbox)
    end

    it 'logs a sent email' do
      expect(sent_mailbox).to receive(:emails).and_return([email])
      expect(all_mailbox).to receive(:emails).and_return([])

      expect(gmail_account).to receive(:log_email).once

      gmail_account.import_emails(account_list)
    end

    it 'logs a received email' do
      expect(sent_mailbox).to receive(:emails).and_return([])
      expect(all_mailbox).to receive(:emails).and_return([email])

      expect(gmail_account).to receive(:log_email).once

      gmail_account.import_emails(account_list)
    end
  end

  context '#log_email' do
    let(:gmail_message) { mock_gmail_message('message body') }
    let(:google_email) { build(:google_email, google_email_id: gmail_message.msg_id, google_account: google_account) }

    def mock_gmail_message(body)
      double(message: double(multipart?: false, body: double(decoded: body)),
             envelope: double(date: Time.zone.now, message_id: '1'),
             subject: 'subject', msg_id: 1)
    end

    it 'creates a completed task' do
      expect do
        expect do
          gmail_account.log_email(gmail_message, account_list, contact, person, 'Done')
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
      task = gmail_account.log_email(gmail_message, account_list, contact, person, 'Done')
      expect(task.subject).to eq('No Subject')
    end

    it 'truncates the subject if the subject is more than 2000 chars' do
      expect(gmail_message).to receive(:subject).twice.and_return('x' * 2001)
      task = gmail_account.log_email(gmail_message, account_list, contact, person, 'Done')
      expect(task.subject).to eq('x' * 2000)
    end

    it "doesn't create a duplicate task" do
      google_email.save
      task = create(:task, account_list: account_list, remote_id: gmail_message.envelope.message_id, source: 'gmail')
      contact.tasks << task
      create(:google_email_activity, google_email: google_email, activity: task)

      expect do
        gmail_account.log_email(gmail_message, account_list, contact, person, 'Done')
      end.not_to change(Task, :count)
    end

    it 'creates a google_email' do
      expect do
        gmail_account.log_email(gmail_message, account_list, contact, person, 'Done')
      end.to change(GoogleEmail, :count).by(1)

      task = GoogleEmail.last
      expect(task.google_email_id).to eq(gmail_message.msg_id)
    end

    it "doesn't create a duplicate google_email" do
      google_email.save

      expect do
        gmail_account.log_email(gmail_message, account_list, contact, person, 'Done')
      end.not_to change(GoogleEmail, :count)
    end

    it 'handles messages with null bytes' do
      expect do
        gmail_account.log_email(mock_gmail_message("\0null\0!"), account_list, contact, person, 'Done')
      end.to change(Task, :count).by(1)
      expect(Task.last.activity_comments.first.body).to eq 'null!'
    end
  end
end
