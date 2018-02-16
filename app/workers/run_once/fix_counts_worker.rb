class RunOnce::FixCountsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_run_once, unique: :until_executed

  def perform(mc_id)
    mc = MailChimpAccount.find_by(id: mc_id)
    fc = FixCount.find_by(account_list_id: mc.account_list_id)
    FixCount.new(account_list_id: mc.account_list_id).run(mc) unless fc
  end
end
