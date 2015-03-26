require 'spec_helper'

describe NotificationType do
  let(:notification_type) { create(:notification_type) }
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let!(:donation) { create(:donation) }
  let(:designation_account) { create(:designation_account) }
  let!(:special_gift) { NotificationType::SpecialGift.create! }

  context '.check_all' do
    it 'checks for notifications of each type' do
      create(:notification_preference, account_list: account_list, notification_type: special_gift)
      NotificationType.should_receive(:types).and_return(['NotificationType::SpecialGift'])
      NotificationType::SpecialGift.should_receive(:first).and_return(special_gift)
      special_gift.should_receive(:check).and_return

      NotificationType.check_all(account_list)
    end
  end

  describe '#create_task default implementation' do
    before do
      description = '%{contact_name} gave a gift of %{amount} on %{date}'
      expect(notification_type).to receive(:task_description_template).and_return(description)
    end

    it 'creates a task for the activity list' do
      donation.update(donation_date: Date.new(2015, 3, 18))
      expect do
        notification_type.create_task(account_list, contact.notifications.new(donation_id: donation.id))
      end.to change(Activity, :count).by(1)
      activity = Activity.first
      expect(activity.subject).to eq('Doe, John gave a gift of MyString9.99 on Mar 18, 2015, 12:00:00 AM')
      expect(activity.activity_type).to eq('Thank')
    end

    it 'associates the contact with the task created' do
      task = notification_type.create_task(account_list, contact.notifications.new(donation_id: donation.id))
      expect(task.contacts.reload).to include(contact)
    end
  end

  describe '#check default implementation' do
    it 'does not add a notification twice' do
      expect(notification_type).to receive(:check_for_donation_to_notify).twice.with(contact).and_return(donation)
      account_list.contacts.reload

      expect do
        notification_type.check(account_list)
      end.to change(Notification, :count).from(0).to(1)

      expect do
        notification_type.check(account_list)
      end.to_not change(Notification, :count).from(1)
    end

    it 'does not send a notification for gifts given a long time ago' do
      donation.update(donation_date: 75.days.ago)
      expect(notification_type).to receive(:check_for_donation_to_notify).with(contact).and_return(donation)
      expect do
        notification_type.check(account_list)
      end.to_not change(Notification, :count).from(0)
    end
  end

  describe '#task_description default implementation' do
    it 'interpolates and localizes contact name, amount and date' do
      donation.update(donation_date: Date.new(2015, 3, 18))
      template = '%{contact_name} gave %{amount} on %{date}'
      expect(notification_type).to receive(:task_description_template).and_return(template)
      notification = contact.notifications.new(donation: donation)
      description = 'Doe, John gave MyString9.99 on Mar 18, 2015, 12:00:00 AM'
      expect(notification_type.task_description(notification)).to eq(description)
    end
  end
end
