require 'rails_helper'

describe GoogleCalendarIntegrator do
  let(:user) { create(:user) }
  let(:google_account) { create :google_account, person: user }
  let(:google_integration) do
    build(:google_integration, google_account: google_account,
                               calendar_integrations: ['Appointment'],
                               calendar_name: 'My Calendar')
  end
  let(:integrator) { google_integration.calendar_integrator }
  let(:task) { create(:task, account_list: google_integration.account_list, activity_type: 'Appointment') }
  let(:google_event) { create(:google_event, activity: task, google_integration: google_integration) }

  let(:missing_event_response) do
    errors = [{ 'domain' => 'global', 'reason' => 'notFound', 'message' => 'Not Found' }]
    double(data: { 'error' => { 'errors' => errors,
                                'code' => 404, 'message' => 'Not Found' } },
           status: 404)
  end

  context '#sync_tasks' do
    it 'calls #sync_task for each future, uncompleted task that is set to be synced' do
      task1 = double(id: 1)
      task2 = double(id: 2)

      allow(google_integration)
        .to receive_message_chain(:account_list, :tasks, :future, :uncompleted, :of_type, :ids)
        .and_return([task1.id, task2.id])
      expect(integrator).to receive(:sync_task).with(task1.id)
      expect(integrator).to receive(:sync_task).with(task2.id)

      integrator.sync_tasks
    end
  end

  context '#sync_task' do
    it 'calls add_task if no google_event exists' do
      expect(integrator).to receive(:add_task).with(task)

      integrator.sync_task(task)
    end

    it 'calls update_task if a google_event exists' do
      allow(google_integration).to receive(:calendars).and_return(nil)
      expect(integrator).to receive(:update_task).with(task, google_event)

      integrator.sync_task(task)
    end

    it 'calls add_task if google_event is for another calendar' do
      allow(google_integration).to receive(:calendars).and_return(nil)
      google_event.update(calendar_id: 'other-calendar')
      expect(integrator).to receive(:add_task).with(task)

      integrator.sync_task(task)
    end

    it 'calls remove_google_event if task is nil' do
      allow(google_integration).to receive(:calendars).and_return(nil)
      expect(integrator).to receive(:remove_google_event).with(google_event)

      task.destroy

      integrator.sync_task(task.id)
    end
  end

  context '#add_task' do
    it 'creates a google_event' do
      allow(google_integration).to receive_message_chain(:calendar_service, :insert_event)
        .and_return(double(id: '1234'))

      expect do
        integrator.send(:add_task, task)
      end.to change(GoogleEvent, :count)

      expect(GoogleEvent.last.calendar_id).to eq('cal1')
      expect(GoogleEvent.last.google_event_id).to eq('1234')
    end

    it 'removes the calendar integration if the calendar no longer exists on google' do
      allow(google_integration).to receive_message_chain(:calendar_service, :insert_event)
        .and_raise(Google::Apis::ClientError.new('error', status_code: 404))

      expect(google_integration.calendar_integration?).to be true
      expect(google_integration.calendar_id).to be_present
      expect(google_integration.calendar_name).to be_present

      integrator.send(:add_task, task)

      expect(google_integration.calendar_integration?).to be false
      expect(google_integration.calendar_id).to be_nil
      expect(google_integration.calendar_name).to be_nil
    end
  end

  context '#update_task' do
    it 'updates a google_event' do
      allow(google_integration).to receive_message_chain(:calendar_service, :patch_event).and_return(double)

      expect(integrator).to_not receive(:add_task)

      google_event.save

      expect do
        integrator.send(:update_task, task, google_event)
      end.to_not change(GoogleEvent, :count)
    end

    it 'adds the google event if it is missing from google' do
      allow(google_integration).to receive_message_chain(:calendar_service, :patch_event)
        .and_raise(Google::Apis::ClientError.new('error', status_code: 404))
      allow(google_integration).to receive_message_chain(:calendar_service, :insert_event)
        .and_return(double(id: '1234'))

      integrator.send(:update_task, task, google_event)

      expect(GoogleEvent.exists?(id: google_event.id)).to eq(false)
      event_attrs = { google_integration_id: google_integration.id, activity_id: task.id, google_event_id: '1234' }
      expect(GoogleEvent.exists?(event_attrs)).to eq(true)
    end
  end

  context '#remove_google_event' do
    it 'deletes a google_event' do
      allow(google_integration).to receive_message_chain(:calendar_service, :delete_event)
      google_event.save
      expect do
        integrator.send(:remove_google_event, google_event)
      end.to change(GoogleEvent, :count).by(-1)
    end
  end

  context '#build_api_event_from_mpdx_task' do
    it 'sets start and end times for tasks with default lengths' do
      event = integrator.send(:build_api_event_from_mpdx_task, task)
      expect(event.start.date_time).to_not be_nil
      expect(event.end.date_time).to_not be_nil
      expect(event.start.date).to be_nil
      expect(event.end.date).to be_nil
    end

    it 'sets an all day event for tasks without default lengths' do
      task.activity_type = 'Thank'
      event = integrator.send(:build_api_event_from_mpdx_task, task)
      expect(event.start.date_time).to be_nil
      expect(event.end.date_time).to be_nil
      expect(event.start.date).to_not be_nil
      expect(event.end.date).to_not be_nil
    end

    it 'respects the user time zone on an all day event' do
      task.activity_type = 'Thank'
      task.start_at = 'Thu, 15 Oct 2015 00:55:00 UTC +00:00'

      user.time_zone = 'Central Time (US & Canada)'
      user.save

      event = integrator.send(:build_api_event_from_mpdx_task, task)
      expect(event.start.date).to eql('2015-10-14')
    end
  end
end
