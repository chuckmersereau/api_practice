require 'rails_helper'

describe GoogleSyncDataWorker do
  let!(:google_integration) { create(:google_integration) }

  it 'tells the GoogleIntegration to sync_data' do
    google_integration_double = instance_double('GoogleIntegration')
    expect(GoogleIntegration).to receive(:find).with(google_integration.id).and_return(google_integration_double)
    expect(google_integration_double).to receive(:sync_data).with('email')
    GoogleSyncDataWorker.new.perform(google_integration.id, 'email')
  end

  it 'returns without error if the GoogleIntegration is not found' do
    expect(GoogleIntegration).to receive(:find).with(google_integration.id).and_raise(ActiveRecord::RecordNotFound)
    expect(GoogleSyncDataWorker.new.perform(google_integration.id, 'email')).to eq(nil)
  end
end
