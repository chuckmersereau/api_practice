class NotificationPreference < ApplicationRecord
  belongs_to :account_list
  belongs_to :notification_type
  belongs_to :user

  validates :account_list, :notification_type, presence: true
  delegate :type, to: :notification_type
  before_save :update_other_notification_preferences, if: :user

  PERMITTED_ATTRIBUTES = [
    :email,
    :task,
    :created_at,
    :id,
    :notification_type_id,
    :overwrite,
    :updated_at,
    :updated_in_db_at,
    :uuid
  ].freeze

  protected

  def update_other_notification_preferences
    create_notification_preference_without_user
    account_list.notification_preferences
                .where(notification_type_id: notification_type_id)
                .where('id != ?', id)
                .update_all(task: task)
  end

  def create_notification_preference_without_user
    account_list.notification_preferences
                .create_with(
                  email: false,
                  task: task
                )
                .find_or_create_by(
                  notification_type_id: notification_type_id,
                  user_id: nil
                )
  end
end
