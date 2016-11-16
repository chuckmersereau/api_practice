class Api::V2::AccountLists::NotificationsController < Api::V2::AccountListsController
  private

  def resource_class
    Notification
  end

  def resource_scope
    current_account_list.notifications
  end
end
