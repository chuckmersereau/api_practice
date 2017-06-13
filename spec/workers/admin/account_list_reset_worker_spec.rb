require 'rails_helper'

describe Admin::AccountListResetWorker do
  let!(:user) { create(:user_with_account) }
  let!(:admin_user) { create(:admin_user) }
  let!(:account_list) { user.account_lists.first }
  let!(:reset_log) { Admin::ResetLog.create!(resetted_user: user, admin_resetting: admin_user, reason: "Because I'm writing a spec!") }

  before do
    create(:user_with_account)
  end

  describe '#perform' do
    subject do
      Admin::AccountListResetWorker.new.perform(account_list.id, user.id, reset_log.id)
    end

    it 'authorizes the reset' do
      expect_any_instance_of(PunditAuthorizer).to receive(:authorize_on).with('create')
      expect do
        expect(subject).to eq(true)
      end.to change { AccountList.count }.by(-1)
    end

    it 'does not destroy the account_list if the admin is not an admin' do
      reset_log.update(admin_resetting: create(:user))
      reset_log.reload
      expect(AccountList::Destroyer).to_not receive(:new).with('create')
      expect do
        expect(subject).to eq(false)
      end.to_not change { AccountList.count }
    end

    it 'continues with the reset if the account_list was already destroyed' do
      account_list.unsafe_destroy
      expect do
        expect(subject).to eq(true)
      end.to_not change { AccountList.count }
    end

    it 'does not reset if the user is not found' do
      user.delete
      expect do
        expect(subject).to eq(false)
      end.to_not change { AccountList.count }
    end

    it 'does not reset if the reset_log is not found' do
      reset_log.delete
      expect do
        expect(subject).to eq(false)
      end.to_not change { AccountList.count }
    end

    it 'deletes the account_list' do
      account_list_id = account_list.id
      expect do
        expect(subject).to eq(true)
      end.to change { AccountList.where(id: account_list_id).count }.from(1).to(0)
        .and change { AccountList.count }.from(3).to(2)
    end

    it 'imports the profiles' do
      expect_any_instance_of(Person::OrganizationAccount).to receive(:import_profiles)
      subject
      expect(user.reload.designation_profiles).to be_blank
    end

    it 'queues a data sync' do
      expect_any_instance_of(Person::OrganizationAccount).to receive(:queue_import_data)
      subject
    end

    it 'logs the complete time' do
      time = Time.current
      travel_to time do
        expect { subject }.to change { reset_log.reload.completed_at&.to_i }.from(nil).to(time.to_i)
      end
    end
  end
end
