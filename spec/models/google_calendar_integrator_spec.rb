require 'spec_helper'

describe GoogleCalendarIntegrator do
  let(:google_integration) { build(:google_integration, calendar_integrations: ['Appointment']) }
  let(:integrator) { GoogleCalendarIntegrator.new(google_integration) }
  let(:task) { create(:task, account_list: google_integration.account_list, activity_type: 'Appointment') }
  let(:google_event) { create(:google_event, activity: task, google_integration: google_integration) }
  let(:missing_event_response) do
    double(data: { 'error' => { 'errors' => [{ 'domain' => 'global', 'reason' => 'notFound', 'message' => 'Not Found' }],
                                'code' => 404, 'message' => 'Not Found' } },
           status: 404)
  end

  context '#sync_tasks' do
    it 'calls #sync_task for each future, uncompleted task that is set to be synced' do
      task1, task2 = double(id: 1), double(id: 2)

      allow(google_integration)
        .to receive_message_chain(:account_list, :tasks, :future, :uncompleted, :of_type)
        .and_return([task1, task2])
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

    it 'calls remove_google_event if task is nil' do
      allow(google_integration).to receive(:calendars).and_return(nil)
      expect(integrator).to receive(:remove_google_event).with(google_event)

      task.destroy

      integrator.sync_task(task.id)
    end
  end

  context '#add_task' do
    it 'creates a google_event' do
      allow(google_integration).to receive_message_chain(:calendar_api, :events, :insert)
        .and_return('')
      expect(integrator.client).to receive(:execute)
        .and_return(double(data: { 'id' => 'foo' }, status: 200))
      expect(integrator).to receive(:event_attributes).and_return({})

      expect do
        integrator.add_task(task)
      end.to change(GoogleEvent, :count)
    end

    it 'removes the calendar integration if the calendar no longer exists on google' do
      allow(google_integration).to receive_message_chain(:calendar_api, :events, :insert)
        .and_return('')
      expect(integrator.client).to receive(:execute).and_return(missing_event_response)
      expect(integrator).to receive(:event_attributes).and_return({})

      integrator.add_task(task)

      expect(google_integration.calendar_integration?).to be false
      expect(google_integration.calendar_id).to be_nil
      expect(google_integration.calendar_name).to be_nil
    end
  end

  context '#update_task' do
    it 'updates a google_event' do
      allow(google_integration).to receive(:calendars).and_return(nil)
      allow(google_integration).to receive_message_chain(:calendar_api, :events, :patch)
        .and_return('')
      expect(integrator.client).to receive(:execute).and_return(double(data: { 'id' => 'foo' }, status: 200))
      expect(integrator).to receive(:event_attributes).and_return({})
      expect(integrator).to_not receive(:add_task)

      google_event.save
      expect do
        integrator.update_task(task, google_event)
      end.to_not change(GoogleEvent, :count)
    end

    it 'adds the google event if it is missing from google' do
      allow(google_integration).to receive(:calendars).and_return(nil)
      allow(google_integration).to receive_message_chain(:calendar_api, :events, :patch)
        .and_return('')
      expect(integrator.client).to receive(:execute).and_return(missing_event_response)
      expect(integrator).to receive(:event_attributes).and_return({})
      expect(integrator).to receive(:add_task)

      integrator.update_task(task, google_event)

      expect(google_event).to_not eq(GoogleEvent.find_by(google_integration_id: google_integration.id, activity_id: task.id))
    end
  end

  context '#remove_google_event' do
    it 'deletes a google_event' do
      allow(google_integration).to receive(:calendars).and_return(nil)
      allow(google_integration).to receive_message_chain(:calendar_api, :events, :delete)
        .and_return('')
      expect(integrator.client).to receive(:execute).and_return(double(data: {}, status: 200))

      google_event.save
      expect do
        integrator.remove_google_event(google_event)
      end.to change(GoogleEvent, :count).by(-1)
    end
  end

  context '#event_attributes' do
    it 'sets start and end times for tasks with default lengths' do
      expect(integrator.event_attributes(task)[:start][:dateTime]).to_not be_nil
      expect(integrator.event_attributes(task)[:end][:dateTime]).to_not be_nil

      expect(integrator.event_attributes(task)[:start][:date]).to be_nil
      expect(integrator.event_attributes(task)[:end][:date]).to be_nil
    end

    it 'sets an all day event for tasks without default lengths' do
      task.activity_type = 'Thank'

      expect(integrator.event_attributes(task)[:start][:dateTime]).to be_nil
      expect(integrator.event_attributes(task)[:end][:dateTime]).to be_nil

      expect(integrator.event_attributes(task)[:start][:date]).to_not be_nil
      expect(integrator.event_attributes(task)[:end][:date]).to_not be_nil
    end
  end
end
