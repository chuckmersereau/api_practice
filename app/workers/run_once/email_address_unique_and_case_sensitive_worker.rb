class RunOnce::EmailAddressUniqueAndCaseSensitiveWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_run_once, unique: :until_executed

  def perform
    duplicates =
      MailChimpMember.group(:mail_chimp_account_id, :list_id, 'lower(email)')
                     .having('count(*) > 1')
                     .pluck('array_agg(id) as ids', :mail_chimp_account_id, :list_id, 'lower(email)')

    duplicates.each do |duplicate|
      members = MailChimpMember.where(id: duplicate[0]).all.sort_by(&:created_at)
      members.pop
      members.each(&:destroy)
    end
  end
end
