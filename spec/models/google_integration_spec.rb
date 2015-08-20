require 'spec_helper'

describe GoogleIntegration do
  let(:google_integration) { build(:google_integration) }
  let(:calendar_data) { Hashie::Mash.new(JSON.parse(File.new(Rails.root.join('spec/fixtures/google_calendar_data.json')).read)) }

  context '#queue_sync_data' do
    it 'queues a data sync when an integration type is passed in' do
      expect(google_integration).to receive(:lower_retry_async)
        .with(:sync_data, 'calendar')
      google_integration.queue_sync_data('calendar')
    end

    it 'does not queue a data sync when an integration type is passed in' do
      expect do
        google_integration.queue_sync_data
      end.to_not change(LowerRetryWorker.jobs, :size)
    end

    it 'queues the google contacts sync integration for the whole account list' do
      google_integration.update(calendar_integration: false, contacts_integration: true)
      expect do
        google_integration.queue_sync_data('contacts')
      end.to change(LowerRetryWorker.jobs, :size).from(0).to(1)

      expect(LowerRetryWorker.jobs.first['args'])
        .to eq(['AccountList', google_integration.account_list.id, 'sync_with_google_contacts'])
    end
  end

  context '#sync_data' do
    it 'triggers a calendar_integration sync' do
      expect(google_integration.calendar_integrator).to receive(:sync_tasks)

      google_integration.sync_data('calendar')
    end
  end

  context '#calendar_integrator' do
    it 'should return the same GoogleCalendarIntegrator instance across multiple calls' do
      expect(google_integration.calendar_integrator).to equal(google_integration.calendar_integrator)
    end
  end

  context '#calendars' do
    let(:calendar_list_api) { double }
    let(:client) { double(execute: double(data: calendar_data)) }

    it 'returns a list of calendars from google' do
      allow(google_integration.google_account).to receive(:client).and_return(client)
      allow(google_integration).to receive_message_chain(:calendar_api, :calendar_list, :list)
        .and_return(calendar_list_api)

      expect(client).to receive(:execute).with(api_method: calendar_list_api,
                                               parameters: { 'userId' => 'me' })

      expect(google_integration.calendars).to eq(calendar_data.items)
    end
  end

  context '#toggle_calendar_integration_for_appointments' do
    before do
      allow(google_integration).to receive(:calendars).and_return([{}])
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
      allow(google_integration).to receive(:calendars).and_return([calendar_data.items.first])
      first_calendar = calendar_data.items.first

      google_integration.set_default_calendar

      expect(google_integration.calendar_id).to eq(first_calendar['id'])
      expect(google_integration.calendar_name).to eq(first_calendar['summary'])
    end

    it 'returns false if the api fails' do
      allow(google_integration).to receive(:calendar_api).and_return(false)

      expect(google_integration.set_default_calendar).to eq(false)
    end

    it 'returns nil if this google account has more than one calendar' do
      allow(google_integration).to receive(:calendars).and_return(calendar_data.items)

      expect(google_integration.set_default_calendar).to eq(nil)
    end
  end

  context '#create_new_calendar' do
    let(:calendar_insert_api) { double }
    let(:client) { double(execute: double(data: calendar_data.items.first)) }

    it 'creates a new calendar' do
      google_integration.calendar_id = nil
      google_integration.new_calendar = 'new calendar'

      allow(google_integration.google_account).to receive(:client).and_return(client)
      allow(google_integration).to receive_message_chain(:calendar_api, :calendars, :insert)
        .and_return(calendar_insert_api)

      expect(client).to receive(:execute).with(api_method: calendar_insert_api,
                                               body_object: { 'summary' => google_integration.new_calendar })

      first_calendar = calendar_data.items.first

      google_integration.create_new_calendar

      expect(google_integration.calendar_id).to eq(first_calendar['id'])
      expect(google_integration.calendar_name).to eq(google_integration.new_calendar)
    end
  end
end
