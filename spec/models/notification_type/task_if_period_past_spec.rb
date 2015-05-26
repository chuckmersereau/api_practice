require 'spec_helper'

describe NotificationType::TaskIfPeriodPast do
  let!(:task_if_period_past) { NotificationType::TaskIfPeriodPast.first_or_initialize }
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, created_at: 3.years.ago, account_list: account_list, status: 'Partner - Financial') }

  context '#check' do
    before { allow(task_if_period_past).to receive(:task_activity_type).and_return('Call') }

    it 'add a notification if an activity came from more than a year ago' do
      create(:task, activity_type: 'Call', contacts: [contact], account_list: contact.account_list,
                    start_at: 2.years.ago)
      notifications = task_if_period_past.check(contact.account_list)
      expect(notifications.length).to eq(1)
    end

    it 'adds no notification if an activity come from a financial partner within a year' do
      create(:task, activity_type: 'Call', contacts: [contact], account_list: contact.account_list,
                    start_at: 5.days.ago)
      notifications = task_if_period_past.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end

    it 'adds a notification for non-monthly partners' do
      contact.update(pledge_frequency: 12.0)
      create(:task, activity_type: 'Call', contacts: [contact], account_list: contact.account_list,
                    start_at: 2.years.ago)
      notifications = task_if_period_past.check(contact.account_list)
      expect(notifications.length).to eq(1)
    end

    it 'add no notification for non-financial partner' do
      contact.update(status: 'Partner - Pray')
      create(:task, activity_type: 'Call', contacts: [contact], account_list: contact.account_list,
                    start_at: 2.years.ago)
      notifications = task_if_period_past.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end

    it 'add no notification if contact is created within a year and first activity is started at within a year' do
      contact.update(created_at: 5.months.ago, status: 'Partner - Financial', pledge_frequency: 1.0)
      create(:task, activity_type: 'Call', contacts: [contact], account_list: contact.account_list,
                    start_at: 5.weeks.ago)
      notifications = task_if_period_past.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end

    it 'add a notification if contact is created within a year and first activity is started more than a year ago' do
      contact.update(created_at: 5.months.ago)
      create(:task, activity_type: 'Call', contacts: [contact], account_list: contact.account_list,
                    start_at: 2.years.ago)
      notifications = task_if_period_past.check(contact.account_list)
      expect(notifications.length).to eq(1)
    end

    it 'add no notification if the notification task was deleted to make sure it check for prior notifications' do
      task = create(:task, activity_type: 'Call', contacts: [contact], account_list: contact.account_list,
                           start_at: 2.weeks.ago)
      contact.notifications.create!(notification_type_id: task_if_period_past.id, event_date: 2.weeks.ago)
      task.destroy
      notifications = task_if_period_past.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end

    it 'add no notification if a contact was created within a year and have no activities imported' do
      contact.update(created_at: 3.months.ago)
      notifications = task_if_period_past.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end
  end
end
