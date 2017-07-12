require 'rails_helper'

describe GoogleSyncDataWorker do
  let!(:google_integration) { create(:google_integration) }

  it 'tells the GoogleIntegration to sync_data' do
    google_integration_double = instance_double('GoogleIntegration')
    expect(GoogleIntegration).to receive(:find).with(google_integration.id).and_return(google_integration_double)
    expect(google_integration_double).to receive(:sync_data).with('email')
    GoogleSyncDataWorker.new.perform(google_integration.id, 'email')
  end
end
