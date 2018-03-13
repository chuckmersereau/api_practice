class AccountListUser < ApplicationRecord
  belongs_to :user
  belongs_to :account_list

  after_create :duplicate_notification_preferences
  after_destroy :destroy_notification_preferences
  after_destroy :change_user_default_account_list_if_needed

  audited on: [:destroy]

  private

  def duplicate_notification_preferences
    account_list.notification_preferences.where(user_id: nil).find_each do |notification_preference|
      notification_preference.dup.tap do |user_notification_preference|
        user_notification_preference.id = nil
        user_notification_preference.user = user
        user_notification_preference.email = true
        user_notification_preference.save!
      end
    end
  end

  def destroy_notification_preferences
    account_list.notification_preferences.where(user: user).destroy_all
  end

  def change_user_default_account_list_if_needed
    return unless user && user.default_account_list == account_list_id
    user.update(default_account_list: user.account_lists.reload.order(:created_at).map(&:id).first)
  end
end
