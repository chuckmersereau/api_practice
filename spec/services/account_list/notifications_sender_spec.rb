require 'rails_helper'

RSpec.describe AccountList::NotificationsSender do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  subject { described_class.new(account_list) }

  describe '#initialize' do
    it 'should set account_list instance variable' do
      expect(subject.instance_variable_get(:@account_list)).to eq account_list
    end
  end

  describe '#send_notifications' do
    it 'should call NotificationType.check_all' do
      expect(NotificationType).to receive(:check_all).and_return({})
      subject.send_notifications
    end

    describe 'notifications to send' do
      let(:contact) { create(:contact, account_list: account_list) }
      let(:notification_type) { create(:notification_type) }
      let(:notification) { create(:notification, contact: contact, notification_type: notification_type) }
      let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

      before do
        allow(NotificationType).to receive(:check_all).and_return(notification_type.type => [notification])
        allow(NotificationType).to receive(:types).and_return([notification_type.type])
        allow(notification_type.class).to receive(:first).and_return(notification_type)
      end

      it 'should create_tasks' do
        account_list.notification_preferences.create(notification_type: notification_type, user: nil, task: true)
        expect(notification_type).to receive(:create_task).with(account_list, notification)
        subject.send_notifications
      end

      it 'should create_emails' do
        account_list.notification_preferences.create(notification_type: notification_type, user: user, email: true)
        allow(notification_type).to receive(:create_task).with(account_list, notification).and_return(nil)
        subject.send_notifications
        expect(NotificationMailer.instance_method(:notify)).to be_delayed(user, notification_type => [notification])
      end
    end
  end
end
