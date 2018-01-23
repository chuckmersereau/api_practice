class ChangeActionsToBooleansOnNotificationPreferences < ActiveRecord::Migration
  def change
    add_column :notification_preferences, :email, :boolean, default: true
    add_column :notification_preferences, :task, :boolean, default: true
    NotificationPreference.find_each(&:convert_actions_array_to_booleans)
    AccountListUser.find_each(&:duplicate_notification_preferences)
    remove_column :notification_preferences, :actions
  end

  class NotificationPreference < ActiveRecord::Base
    belongs_to :user
    belongs_to :account_list

    serialize :actions, Array

    def convert_actions_array_to_booleans
      update_attributes(
        email: actions.include?('email'),
        task: actions.include?('task')
      )
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
