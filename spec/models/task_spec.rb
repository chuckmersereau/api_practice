require 'spec_helper'

describe Task do
  let(:account_list) { create(:account_list) }
  it 'updates a related contacts uncompleted tasks count' do
    task1 = create(:task, account_list: account_list)
    task2 = create(:task, account_list: account_list)
    contact = create(:contact, account_list: account_list)
    contact.tasks << task1
    contact.tasks << task2
    expect(contact.reload.uncompleted_tasks_count).to eq(2)

    task1.reload.update_attributes(completed: true)

    expect(contact.reload.uncompleted_tasks_count).to eq(1)

    task1.update_attributes(completed: false)

    expect(contact.reload.uncompleted_tasks_count).to eq(2)

    task2.destroy
    expect(contact.reload.uncompleted_tasks_count).to eq(1)
  end

  context 'google calendar integration' do
    let(:google_integration) { double('GoogleIntegration', async: true) }

    before do
      allow_any_instance_of(AccountList).to receive(:google_integrations) { [google_integration] }
    end

    it 'does not sync an old task to google after a save call' do
      expect(google_integration).to_not receive(:lower_retry_async)

      create(:task, account_list: account_list, activity_type: 'Appointment')
    end

    it 'does not sync a completed task to google after a save call' do
      expect(google_integration).to_not receive(:lower_retry_async)

      create(:task, result: 'completed', account_list: account_list, activity_type: 'Appointment')
    end

    it 'syncs a task to google after a save call' do
      expect(google_integration).to receive(:lower_retry_async)

      create(:task, start_at: 1.day.from_now, account_list: account_list, activity_type: 'Appointment')
    end

    it 'syncs a task to google after a destroy call' do
      expect(google_integration).to receive(:lower_retry_async).twice

      create(:task, start_at: 1.day.from_now, account_list: account_list, activity_type: 'Appointment').destroy
    end
  end

  context '#calculate_location' do
    let(:contact) { create(:contact, account_list: account_list) }
    let(:person) { create(:person) }
    let(:task) { create(:task, account_list: account_list) }
    before do
      contact.people << person
      task.contacts << contact
    end

    it 'users numbers if call' do
      task.update_column(:activity_type, 'Call')
      person.phone_numbers << create(:phone_number)
      expect(task.calculated_location).to eq 'John Smith (123) 456-7890 - mobile'
    end

    it 'uses address for non-calls' do
      contact.addresses << create(:address)
      task.update_column(:activity_type, 'Appointment')
      address = '123 Somewhere St, Fremont, CA, 94539, United States'
      expect(task.calculated_location).to eq address
    end
  end
end
