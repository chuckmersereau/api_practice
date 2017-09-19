require 'rails_helper'

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
    let(:google_integration) { double('GoogleIntegration', async: true, id: 1234) }

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

    it 'does not sync a task with has been specified as having no date' do
      expect(google_integration).to_not receive(:lower_retry_async)

      create(:task, start_at: 1.day.from_now, no_date: true, account_list: account_list, activity_type: 'Appointment')
      create(:task, start_at: nil, account_list: account_list, activity_type: 'Appointment')
    end

    it 'syncs a task to google after a save call' do
      task = build(:task, start_at: 1.day.from_now, account_list: account_list, activity_type: 'Appointment')

      expect { task.save }.to change { GoogleCalendarSyncTaskWorker.jobs.size }.by(1)

      expect(GoogleCalendarSyncTaskWorker.jobs.last['args']).to eq([1234, task.id])
    end

    it 'syncs a task to google after a destroy call' do
      expect(GoogleCalendarSyncTaskWorker).to receive(:perform_async).twice

      create(:task, start_at: 1.day.from_now, account_list: account_list, activity_type: 'Appointment').destroy
    end
  end

  context '#calculate_location' do
    let(:contact) { create(:contact, account_list: account_list) }
    let(:person) { create(:person, first_name: 'John', last_name: 'Smith') }
    let(:task) { create(:task, account_list: account_list) }
    before do
      contact.people << person
      task.contacts << contact
    end

    it 'users numbers if call' do
      task.update_column(:activity_type, 'Call')
      person.phone_numbers << create(:phone_number)
      expect(task.calculated_location).to eq 'John Smith (213) 456-7890 - mobile'
    end

    it 'uses address for non-calls' do
      contact.addresses << create(:address)
      task.update_column(:activity_type, 'Appointment')
      address = '123 Somewhere St, Fremont, CA, 94539, United States'
      expect(task.calculated_location).to eq address
    end
  end

  describe '.alert_frequencies' do
    subject { Task.alert_frequencies }

    it 'returns a hash of {String => String}' do
      is_expected.to be_a_hash_with_types(String, String)
    end
  end

  context 'logging newsletter' do
    subject { build(:task, account_list: account_list) }
    let!(:contact_1) { create(:contact, account_list: account_list, send_newsletter: 'Email') }
    let!(:contact_2) { create(:contact, account_list: account_list, send_newsletter: 'Physical') }
    let!(:contact_3) { create(:contact, account_list: account_list, send_newsletter: 'Both') }

    before do
      subject.comments.build(body: 'test')
    end

    context 'physical' do
      before do
        subject.activity_type = 'Newsletter - Physical'
      end

      it 'creates two seperate log newsletter tasks' do
        expect { subject.save }.to change { Task.count }.from(0).to(3)
      end

      it 'creates two seperate comments' do
        expect { subject.save }.to change { ActivityComment.count }.from(0).to(3)
      end

      it 'creates tasks associated to correct contacts' do
        subject.save
        expect(contact_1.tasks.empty?).to be_truthy
        expect(contact_2.tasks.empty?).to be_falsy
        expect(contact_3.tasks.empty?).to be_falsy
      end

      it 'copies attributes to created tasks' do
        subject.save
        created_task = contact_3.tasks.first
        expect(created_task.subject).to eq(subject.subject)
        expect(created_task.activity_type).to eq(subject.activity_type)
        expect(created_task.completed_at).to eq(subject.completed_at)
        expect(created_task.completed).to eq(subject.completed)
      end
    end
    context 'email' do
      context 'with source Nil' do
        before do
          subject.activity_type = 'Newsletter - Email'
          subject.source = nil
        end

        it 'does not create a seperate log newsletter tasks' do
          expect { subject.save }.to change { Task.count }.from(0).to(3)
        end

        it 'creates two seperate comments' do
          expect { subject.save }.to change { ActivityComment.count }.from(0).to(3)
        end

        it 'creates tasks associated to correct contacts' do
          subject.save
          expect(contact_1.tasks.empty?).to be_falsy
          expect(contact_2.tasks.empty?).to be_truthy
          expect(contact_3.tasks.empty?).to be_falsy
        end

        it 'copies attributes to created tasks' do
          subject.save
          created_task = contact_3.tasks.first
          expect(created_task.subject).to eq(subject.subject)
          expect(created_task.activity_type).to eq(subject.activity_type)
          expect(created_task.completed_at).to eq(subject.completed_at)
          expect(created_task.completed).to eq(subject.completed)
        end
      end
      context 'with source MailChimp' do
        before do
          subject.activity_type = 'Newsletter - Email'
          subject.source = 'MailChimp'
        end

        it 'does not create seperate log newsletter tasks' do
          expect { subject.save }.to change { Task.count }.from(0).to(1)
        end

        it 'creates two seperate comments' do
          expect { subject.save }.to change { ActivityComment.count }.from(0).to(1)
        end
      end
    end
  end

  describe '#update_completed_at' do
    context 'complete' do
      it 'sets completed_at, start_at, and result on create' do
        task = build(:task, completed: true, start_at: nil, result: nil)
        travel_to Time.current do
          expect { task.save }.to change { task.completed_at }.from(nil).to(Time.current)
            .and change { task.start_at }.from(nil).to(Time.current)
            .and change { task.result }.from(nil).to('Done')
        end
      end

      it 'sets completed_at, start_at, and result on update' do
        task = create(:task, completed: false, start_at: nil, result: nil)
        task.completed = true
        travel_to Time.current do
          expect { task.save }.to change { task.completed_at }.from(nil).to(Time.current)
            .and change { task.start_at }.from(nil).to(Time.current)
            .and change { task.result }.from(nil).to('Done')
        end
      end
    end

    context 'not complete' do
      it 'sets completed_at, start_at, and result on create' do
        task = build(:task, completed: false, start_at: nil, result: nil)
        travel_to Time.current do
          expect { task.save }.to_not change { task.completed_at }.from(nil)
        end
        expect(task.start_at).to eq(nil)
        expect(task.result).to eq(nil)
      end

      it 'sets completed_at, start_at, and result on update' do
        original_completed_at = 1.month.ago
        task = create(:task, completed: true, completed_at: original_completed_at, start_at: nil, result: nil)
        travel_to Time.current do
          expect { task.update(completed: false) }.to change { task.completed_at }.from(original_completed_at).to(nil)
          expect(task.start_at).to eq(original_completed_at)
          expect(task.result).to eq('')
        end
      end
    end
  end
end
