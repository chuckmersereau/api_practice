require 'rails_helper'

describe GoogleIntegration do
  let(:google_integration) { build(:google_integration) }
  let(:calendar_list_entry) { double(id: '1234', summary: 'My Calendar', access_role: 'owner') }

  context '#queue_sync_data' do
    it 'queues a data sync when an integration type is passed in' do
      google_integration.save
      expect(GoogleSyncDataWorker).to receive(:perform_async).with(google_integration.id, 'calendar')
      google_integration.queue_sync_data('calendar')
    end

    it 'does not queue a data sync when the record is not saved' do
      expect do
        google_integration.queue_sync_data('calendar')
      end.to raise_error(RuntimeError, 'Cannot queue sync on an unpersisted record!')
    end

    it 'does not queue a data sync when a bad integration type is passed in' do
      google_integration.save
      expect do
        google_integration.queue_sync_data('bad')
      end.to raise_error(RuntimeError, "Invalid integration 'bad'!")
    end
  end

  context '#sync_data' do
    it 'triggers a calendar_integration sync' do
      expect(google_integration.calendar_integrator).to receive(:sync_data)
      google_integration.sync_data('calendar')
    end
  end

  context '#calendar_integrator' do
    it 'should return the same GoogleCalendarIntegrator instance across multiple calls' do
      expect(google_integration.calendar_integrator).to equal(google_integration.calendar_integrator)
    end
  end

  context '#calendars' do
    let(:calendar_list_entry_owner) { double(id: '1234', summary: 'My Calendar', access_role: 'owner') }
    let(:calendar_list_entry_nonowner) { double(id: '1234', summary: 'My Calendar', access_role: 'nonowner') }
    let(:calendar_list) { [calendar_list_entry_nonowner, calendar_list_entry_owner] }

    it 'returns a list of calendars from google with access_role owner' do
      allow(google_integration).to receive_message_chain(:calendar_service, :list_calendar_lists, :items)
        .and_return(calendar_list)
      expect(google_integration.calendars).to eq([calendar_list_entry_owner])
    end
  end

  context '#toggle_calendar_integration_for_appointments' do
    before do
      allow(google_integration).to receive(:calendars).and_return([])
      google_integration.calendar_id = ''
      google_integration.calendar_integrations = []
      google_integration.calendar_integration = true
      google_integration.save!
    end

    it 'turns on Appointment syncing if calendar_integration is enabled and nothing is specified' do
      expect(google_integration.calendar_integrations).to eq(['Appointment'])
    end

    it 'remove calendar_integrations when calendar_integration is set to false' do
      google_integration.calendar_integrations = ['Appointment']
      google_integration.calendar_integration = false
      google_integration.save
      expect(google_integration.calendar_integrations).to eq([])
    end
  end

  context '#set_default_calendar' do
    before do
      google_integration.calendar_id = nil
    end

    it 'defaults to the first calendar if this google account only has 1' do
      allow(google_integration).to receive(:calendars).and_return([calendar_list_entry])
      first_calendar = calendar_list_entry

      google_integration.send(:set_default_calendar)

      expect(google_integration.calendar_id).to eq(first_calendar.id)
      expect(google_integration.calendar_name).to eq(first_calendar.summary)
    end

    it 'returns nil if the api fails' do
      allow(google_integration).to receive(:calendar_service).and_return(nil)

      expect(google_integration.send(:set_default_calendar)).to eq(nil)
    end

    it 'returns nil if this google account has more than one calendar' do
      allow(google_integration).to receive(:calendars).and_return([calendar_list_entry, calendar_list_entry])

      expect(google_integration.send(:set_default_calendar)).to eq(nil)
    end
  end
end
