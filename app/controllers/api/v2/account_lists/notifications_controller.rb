class Api::V2::AccountLists::NotificationsController < Api::V2::AccountListsController
  def index
    load_resources
    authorize @account_list, :show?
    render json: @resources
  end

  private

  def resource_class
    Notification
  end

  def resource_scope
    current_account_list.notifications
  end
end
