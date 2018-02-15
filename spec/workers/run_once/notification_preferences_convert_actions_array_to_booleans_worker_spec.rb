require 'rails_helper'

RSpec.describe RunOnce::NotificationPreferencesConvertActionsArrayToBooleansWorker do
  let(:account_list) { create(:account_list) }
  let(:type) { create(:notification_type) }
  let!(:notification_preference) { create(:notification_preference, notification_type: type, account_list: account_list) }

  describe '#perform' do
    context 'actions = [email]' do
      it 'only sets email: true' do
        described_class.new.perform

        notification_preference.reload
        expect(notification_preference.email).to be true
        expect(notification_preference.task).to be false
      end
    end
  end
end
