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

  context '#update' do
    let(:user) { create(:user_with_account) }
    let(:google_integration) do
      create(:google_integration, calendar_integration: false,
                                  account_list: user.account_lists.first)
    end

    before { login(user) }

    it 'queues google contact sync if contact integration set' do
      expect do
        put :update, id: google_integration.id,
                     google_integration: { contacts_integration: true }
        expect(response).to redirect_to(google_integration)
      end.to change(LowerRetryWorker.jobs, :size).by(1)
      expect(google_integration.reload.contacts_integration).to be true
    end
  end
end
