require 'rails_helper'

describe GoogleIntegrationSerializer do
  let(:google_integration) { create(:google_integration) }
  let(:calendar_list_entry_one) { double(id: 'cru.org_iq9ig73eksd81o37afmosu4nts@group.calendar.google.com', summary: 'MPDX Scrum', access_role: 'owner') }
  let(:calendar_list_entry_two) { double(id: 'test.test@cru.org', summary: 'test.test@cru.org', access_role: 'owner') }

  subject { GoogleIntegrationSerializer.new(google_integration).as_json }

  describe '#calendars' do
    before do
      allow(google_integration).to(receive(:calendars).and_return([calendar_list_entry_one, calendar_list_entry_two]))
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
