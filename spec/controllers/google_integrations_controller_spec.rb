require 'spec_helper'

describe GoogleIntegrationsController do
  subject { GoogleIntegrationsController.new }

  context '#split_calendar_id_and_name' do
    it 'splits apart the calendar_id_and_name param' do
      params = { google_integration: { calendar_id_and_name: '["1", "a"]' } }
      expect(subject).to receive(:params).at_least(:once) { params }

      expected_params = {
        google_integration: { calendar_id: '1', calendar_name: 'a' }
      }
      subject.send(:split_calendar_id_and_name)
      expect(subject.params).to eq(expected_params)
    end
  end
end
