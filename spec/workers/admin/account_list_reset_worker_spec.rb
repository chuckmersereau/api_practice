require 'rails_helper'

describe Admin::AccountListResetWorker do
  let!(:user) { create(:user_with_account) }
  let!(:admin_user) { create(:admin_user) }
  let!(:account_list) { user.account_lists.first }
  let!(:reset_log) { Admin::ResetLog.create!(resetted_user: user, admin_resetting: admin_user, reason: "Because I'm writing a spec!") }

  before do
    create(:user_with_account)
    user.update(default_account_list: account_list.id)
  end

  subject do
    Admin::AccountListResetWorker.new.perform(account_list.id, user.id, reset_log.id)
  end

  context 'user has multiple account lists' do
    before do
      create(:organization_account, person: user)
      user.reload
      expect(user.account_lists.size).to eq(2)
    end

    describe '#perform' do
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
          .and change { AccountList.count }.from(4).to(3)
      end

      it 'imports the profiles' do
        organization_account_double = instance_double('Person::OrganizationAccount', queue_import_data: nil, import_profiles: nil)
        expect_any_instance_of(User).to receive(:organization_accounts).once.and_return([organization_account_double])
        expect_any_instance_of(Admin::AccountListResetWorker).to receive(:queue_import_organization_data).once
        expect(organization_account_double).to receive(:import_profiles)
        subject
      end

      it 'queues a data sync' do
        number_of_times_called = 0
        Person::OrganizationAccount.any_instance.stub(:queue_import_data) { number_of_times_called += 1 }
        subject
        expect(number_of_times_called).to eq(user.organization_accounts.size)
        expect(user.organization_accounts.size).to eq(2)
      end

      it 'logs the complete time' do
        time = Time.current
        travel_to time do
          expect { subject }.to change { reset_log.reload.completed_at&.to_i }.from(nil).to(time.to_i)
        end
      end

      it 'updates the default_account_list' do
        expect { subject }.to change { user.reload.default_account_list }.from(account_list.id)
        expect(user.account_lists.ids).to include(user.default_account_list)
      end

      it 'resets the organization account last_download so that all donations are reimported' do
        organization_accounts = account_list.organization_accounts
        organization_accounts.first.update(last_download: 1.day.ago)
        original_time = organization_accounts.first.reload.last_download
        organization_accounts.second.update(last_download: original_time)
        expect { subject }.to change { organization_accounts.first.reload.last_download }.from(original_time).to(nil)
          .and change { organization_accounts.second.reload.last_download }.from(original_time).to(nil)
      end
    end
  end

  context 'user has only one account list' do
    before do
      expect(user.account_lists.size).to eq(1)
    end

    context 'user has no organization account' do
      before do
        user.organization_accounts.delete_all
        user.reload
        expect(user.organization_accounts.size).to eq(0)
      end

      it 'updates the default_account_list' do
        expect { subject }.to change { user.reload.default_account_list }.from(account_list.id).to(nil)
      end
    end

    context 'user has an organization account' do
      let(:org_account_double_class) do
        Class.new do
          def initialize(user)
            @user = user
          end

          def new_account_list
            @new_account_list = FactoryGirl.create(:account_list)
          end

          def import_profiles
            @user.account_lists << @new_account_list
          end

          def queue_import_data
          end
        end
      end
      let(:org_account_double) { org_account_double_class.new(user) }
      let(:new_account_list) { org_account_double.new_account_list }

      before do
        expect(user.organization_accounts.size).to eq(1)
        expect_any_instance_of(Admin::AccountListResetWorker).to receive(:queue_import_organization_data)
        expect_any_instance_of(User).to receive(:organization_accounts).once.and_return([org_account_double])
      end

      it 'updates the default_account_list' do
        expect { subject }.to change { user.reload.default_account_list }.from(account_list.id).to(new_account_list.id)
      end
    end
  end
end
