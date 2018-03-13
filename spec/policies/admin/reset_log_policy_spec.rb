require 'rails_helper'

RSpec.describe Admin::ResetLogPolicy do
  let!(:resetted_user) { create(:user) }
  let!(:admin_resetting) { create(:admin_user) }
  let!(:reason) { 'Just testing this out :)' }
  let!(:reset_log) do
    Admin::ResetLog.create(resetted_user: resetted_user, admin_resetting: admin_resetting, reason: reason)
  end

  describe 'authorize create' do
    subject { PunditAuthorizer.new(admin_resetting, reset_log).authorize_on('create') }

    it 'does raise any errors when authorized' do
      expect { subject }.to_not raise_error
    end

    it 'is raises error when the record is invalid' do
      reset_log.reason = nil
      expect(reset_log.valid?).to eq false
      expect { subject }.to raise_error Pundit::NotAuthorizedError
    end

    it 'is raises error when admin_resetting is not an admin' do
      reset_log.admin_resetting = create(:user)
      expect(reset_log.valid?).to eq true
      expect { subject }.to raise_error Pundit::NotAuthorizedError
    end

    it 'is raises error when resetted_user is no longer in the database' do
      reset_log.resetted_user = nil
      reset_log.resetted_user_id = SecureRandom.uuid
      expect(reset_log.valid?).to eq true
      expect { subject }.to raise_error Pundit::NotAuthorizedError
    end

    it 'is raises error if it is too old' do
      reset_log.update_column(:created_at, 1.month.ago)
      expect(reset_log.valid?).to eq true
      expect { subject }.to raise_error Pundit::NotAuthorizedError
    end

    it 'is raises error if the reset already happened' do
      reset_log.update_column(:completed_at, 1.month.ago)
      expect(reset_log.valid?).to eq true
      expect { subject }.to raise_error Pundit::NotAuthorizedError
    end
  end
end
