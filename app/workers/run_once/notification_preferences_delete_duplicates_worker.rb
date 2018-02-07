# Execute 1
class RunOnce::NotificationPreferencesDeleteDuplicatesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_run_once, unique: :until_executed

  def perform
    AccountList.includes(:notification_preferences)
               .where.not(notification_preferences: { id: nil })
               .find_each(&method(:dedup))
  end

  protected

  def dedup(account_list)
    # notification_preferences should be loaded in memory already
    account_list.notification_preferences.to_a.group_by(&:notification_type_id).each do |_key, group|
      # is there only one preference for this account_list/notification_type combo?
      next if group.count <= 1
      group[1..-1].each(&:destroy!)
    end
  end
end
