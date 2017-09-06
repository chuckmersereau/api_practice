class AccountListImportDataEnqueuerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_account_list_import_data_enqueuer_worker, unique: :until_executed

  def perform
    account_list_ids_to_import.each do |account_list_id|
      Sidekiq::Client.push(
        'class' => AccountList,
        'args'  => [account_list_id, :import_data],
        'queue' => :api_account_list_import_data
      )
    end
  end

  private

  def account_list_scope(users:, last_attempt: Time.current)
    AccountList.with_linked_org_accounts
               .has_users(users)
               .where('last_download_attempt_at IS NULL OR last_download_attempt_at <= ?', last_attempt)
  end

  def account_list_ids_to_import
    @account_list_ids_to_import ||= (
      account_list_scope(users: active_users).pluck(:id) +
      account_list_scope(users: inactive_users, last_attempt: 1.week.ago).pluck(:id)
    ).uniq
  end

  def active_users
    User.where('current_sign_in_at >= ?', active_user_cutoff_time)
  end

  def inactive_users
    User.where('current_sign_in_at IS NULL OR current_sign_in_at < ?', active_user_cutoff_time)
  end

  def active_user_cutoff_time
    @active_user_cutoff_time ||= 2.months.ago
  end
end
