require 'spec_helper'

describe NotificationType::MissingContactInfo do
  subject { NotificationType::MissingContactInfo.create }
  let(:contact) { create(:contact) }
  let(:account_list) { contact.account_list }

  before do
    allow(subject).to receive(:missing_info_filter).with([contact]) { [contact] }
  end

  describe '#check' do
    it 'creates notifications for filtered missing info contacts' do
      notifications = subject.check(account_list)
      expect(notifications.size).to eq(1)
      notification = notifications.first
      expect(notification.new_record?).to be_falsey
      expect(notification.event_date).to be_present
      expect(notification.contact).to eq(contact)
      expect(notification.notification_type_id).to eq(subject.id)
    end

    it 'does not create notifications if no filtered contacts' do
      allow(subject).to receive(:missing_info_filter).with([contact]) { [] }
      expect do
        expect(subject.check(account_list)).to eq([])
      end.to_not change(Notification, :count)
    end

    it 'does not create a notification a second time' do
      expect { subject.check(account_list) }.to change(Notification, :count).by(1)
      expect { subject.check(account_list) }.to_not change(Notification, :count)
    end

    it 'does create a notification if the last one was over a year ago' do
      notification = subject.check(account_list).first
      notification.update(event_date: 2.years.ago)
      expect { subject.check(account_list) }.to change(Notification, :count).by(1)
    end
  end
end
