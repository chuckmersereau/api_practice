require 'rails_helper'

describe AccountListImportDataEnqueuerWorker do
  def expect_user_to_be_enqueued(user)
    user.account_lists.each do |account_list|
      expect(Sidekiq::Client).to receive(:push).with(
        'class' => AccountList,
        'args'  => [account_list.id, :import_data],
        'queue' => :api_account_list_import_data
      ).once
    end
  end

  def expect_user_to_not_be_enqueued(user)
    user.account_lists.each do |account_list|
      expect(Sidekiq::Client).to_not receive(:push).with(
        'class' => AccountList,
        'args'  => [account_list.id, :import_data],
        'queue' => :api_account_list_import_data
      )
    end
  end

  subject { AccountListImportDataEnqueuerWorker.new.perform }

  context 'queuing multiple jobs at a time' do
    let!(:first_active_user) { create(:user_with_full_account, current_sign_in_at: 1.day.ago) }
    let!(:second_active_user) { create(:user_with_full_account, current_sign_in_at: 1.month.ago) }

    let!(:inactive_user) do
      create(:user_with_full_account, current_sign_in_at: 70.days.ago).tap do |user|
        user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: Time.current)
      end
    end

    let!(:account_list_without_org_account) { create(:account_list) }

    it 'queues jobs for active users' do
      expect_user_to_be_enqueued(first_active_user)
      expect_user_to_be_enqueued(second_active_user)
      expect_user_to_not_be_enqueued(inactive_user)

      expect(Sidekiq::Client).to_not receive(:push).with(
        'class' => AccountList,
        'args'  => [account_list_without_org_account.id, :import_data],
        'queue' => :api_account_list_import_data
      )

      subject
    end
  end

  context 'a user has signed in recently' do
    let!(:user) { create(:user_with_full_account, current_sign_in_at: 10.days.ago) }

    it 'queues a job if the last_download_attempt_at is recent' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: Time.current)
      expect_user_to_be_enqueued(user)
      subject
    end

    it 'queues a job if the last_download_attempt_at is more than a week ago' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: 8.days.ago)
      expect_user_to_be_enqueued(user)
      subject
    end

    it 'queues a job if the last_download_attempt_at is blank' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: nil)
      expect_user_to_be_enqueued(user)
      subject
    end
  end

  context 'a user has not signed in for a long time' do
    let!(:user) { create(:user_with_full_account, current_sign_in_at: 90.days.ago) }

    it 'does not queue a job if the last_download_attempt_at is recent' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: 3.days.ago)
      expect_user_to_not_be_enqueued(user)
      subject
    end

    it 'queues a job if the last_download_attempt_at is more than a week ago' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: 8.days.ago)
      expect_user_to_be_enqueued(user)
      subject
    end

    it 'queues a job if the last_download_attempt_at is blank' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: nil)
      expect_user_to_be_enqueued(user)
      subject
    end
  end

  context 'a user has never signed in' do
    let!(:user) { create(:user_with_full_account, current_sign_in_at: nil) }

    it 'does not queue a job if the last_download_attempt_at is recent' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: 3.days.ago)
      expect_user_to_not_be_enqueued(user)
      subject
    end

    it 'queues a job if the last_download_attempt_at is more than a week ago' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: 8.days.ago)
      expect_user_to_be_enqueued(user)
      subject
    end

    it 'queues a job if the last_download_attempt_at is blank' do
      user.account_lists.first.organization_accounts.first.update!(last_download_attempt_at: nil)
      expect_user_to_be_enqueued(user)
      subject
    end
  end
end
