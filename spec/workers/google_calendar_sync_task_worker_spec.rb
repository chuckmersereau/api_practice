require 'rails_helper'

describe GoogleCalendarSyncTaskWorker do
  let(:task_id) { 1 }
  let(:google_integration_id) { 2 }

  it 'tells the GoogleCalendarIntegrator to sync_task' do
    google_integration_double = instance_double('GoogleIntegration')
    calendar_integrator_double = instance_double('GoogleCalendarIntegrator')
    expect(GoogleIntegration).to receive(:find).with(google_integration_id).and_return(google_integration_double)
    expect(google_integration_double).to receive(:calendar_integrator).and_return(calendar_integrator_double)
    expect(calendar_integrator_double).to receive(:sync_task).with(task_id)
    GoogleCalendarSyncTaskWorker.new.perform(google_integration_id, task_id)
  end
end
