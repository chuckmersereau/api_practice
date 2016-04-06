class AccountList::DeepResetWorker
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform(account_list_id, user_id)
    AccountList::DeepReset.new(account_list_id, user_id).reset
  end
end
