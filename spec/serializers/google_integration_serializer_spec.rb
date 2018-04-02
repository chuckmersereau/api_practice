require 'rails_helper'

describe GoogleIntegrationSerializer do
  let(:cru_cal_id) { 'cru.org_iq9ig73eksd81o37afmosu4nts@group.calendar.google.com' }
  let(:google_integration) { create(:google_integration) }
  let(:calendar_list_entry_one) do
    double(id: cru_cal_id, summary: 'MPDX Scrum', access_role: 'owner')
  end
  let(:calendar_list_entry_two) do
    double(id: 'test.test@cru.org', summary: 'test.test@cru.org', access_role: 'owner')
  end

  subject { GoogleIntegrationSerializer.new(google_integration).as_json }

  describe '#calendars' do
    before do
      allow(google_integration).to(receive(:calendars)
                               .and_return([calendar_list_entry_one, calendar_list_entry_two]))
    end

    it 'returns a list of calendars with id and name' do
      expect(subject[:calendars]).to eq [{
        id: cru_cal_id,
        name: 'MPDX Scrum'
      }, {
        id: 'test.test@cru.org',
        name: 'test.test@cru.org'
      }]
    end
  end
end
