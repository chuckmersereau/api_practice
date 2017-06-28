require 'rails_helper'

describe GoogleIntegrationSerializer do
  before do
    stub_request(:get, 'https://www.googleapis.com/discovery/v1/apis/calendar/v3/rest')
      .to_return(status: 200, body: '', headers: {})
  end

  let(:google_integration) { create(:google_integration) }

  subject { GoogleIntegrationSerializer.new(google_integration).as_json }

  describe '#calendars' do
    before do
      allow(google_integration).to(
        receive(:calendars).and_return([
                                         {
                                           'kind' => 'calendar#calendarListEntry',
                                           'etag' => '"1492740723639000"',
                                           'id' => 'cru.org_iq9ig73eksd81o37afmosu4nts@group.calendar.google.com',
                                           'summary' => 'MPDX Scrum',
                                           'timeZone' => 'America/New_York',
                                           'colorId' => '6',
                                           'backgroundColor' => '#ffad46',
                                           'foregroundColor' => '#000000',
                                           'selected' => true,
                                           'accessRole' => 'owner',
                                           'defaultReminders' => []
                                         },
                                         {
                                           'kind' => 'calendar#calendarListEntry',
                                           'etag' => '"1492740720182000"',
                                           'id' => 'test.test@cru.org',
                                           'summary' => 'test.test@cru.org',
                                           'timeZone' => 'Pacific/Auckland',
                                           'colorId' => '14',
                                           'backgroundColor' => '#9fe1e7',
                                           'foregroundColor' => '#000000',
                                           'accessRole' => 'owner',
                                           'defaultReminders' => [
                                             {
                                               'method' => 'popup',
                                               'minutes' => 10
                                             }
                                           ],
                                           'notificationSettings' => {
                                             'notifications' => [
                                               {
                                                 'type' => 'eventCreation',
                                                 'method' => 'email'
                                               },
                                               {
                                                 'type' => 'eventChange',
                                                 'method' => 'email'
                                               },
                                               {
                                                 'type' => 'eventCancellation',
                                                 'method' => 'email'
                                               },
                                               {
                                                 'type' => 'eventResponse',
                                                 'method' => 'email'
                                               }
                                             ]
                                           },
                                           'primary' => true
                                         }
                                       ]))
    end

    it 'returns a list of calendars with id and name' do
      expect(subject[:calendars]).to eq [{
        id: 'cru.org_iq9ig73eksd81o37afmosu4nts@group.calendar.google.com',
        name: 'MPDX Scrum'
      }, {
        id: 'test.test@cru.org',
        name: 'test.test@cru.org'
      }]
    end
  end
end
