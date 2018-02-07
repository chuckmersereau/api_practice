class ChangeActionsToBooleansOnNotificationPreferences < ActiveRecord::Migration
  def change
    add_column :notification_preferences, :email, :boolean, default: true
    add_column :notification_preferences, :task, :boolean, default: true
    NotificationPreference.delete_duplicates
    NotificationPreference.find_each(&:convert_actions_array_to_booleans)
    AccountListUser.includes(:user).where.not(people: { id: nil }).find_each(&:duplicate_notification_preferences)
    remove_column :notification_preferences, :actions
  end

  class NotificationPreference < ActiveRecord::Base
    belongs_to :user
    belongs_to :account_list
    belongs_to :notification_type

    serialize :actions, Array

    def convert_actions_array_to_booleans
      update_attributes(
        email: actions.include?('email'),
        task: actions.include?('task')
      )
    end

    def self.delete_duplicates
      deleted = 0

      account_lists_with_prefs = AccountList.includes(:notification_preferences).where.not(notification_preferences: { id: nil })

      account_lists_with_prefs.find_each do |account_list|
        # notification_preferences should be loaded in memory already
        groups = account_list.notification_preferences.to_a.group_by(&:notification_type_id)

        groups.each do |_key, group|
          # is there only one preference for this account_list/notification_type combo?
          next if group.count <= 1

          group[1..-1].each(&:destroy!)
          deleted += (group.count - 1)
        end
      end

      puts "Deleted #{deleted} duplicate notification preferences"
    end
  end

  class AccountList < ActiveRecord::Base
    has_many :notification_preferences
  end

  class AccountListUser < ActiveRecord::Base
    belongs_to :user
    belongs_to :account_list

    def duplicate_notification_preferences
      account_list.notification_preferences.where(user_id: nil).find_each do |notification_preference|
        notification_preference.dup.tap do |user_notification_preference|
          user_notification_preference.uuid = nil
          user_notification_preference.user = user
          user_notification_preference.save!
        end
      end
    end
  end
end
