class AccountList::DeepResetWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_account_list_deep_reset_worker, unique: :until_executed

  def perform(account_list_id, user_id)
    AccountList::DeepReset.new(account_list_id, user_id).reset
  end
end
