module Api
  module V2
    module AccountLists
      class NotificationsController < AccountListsController
        def resource_attributes
          Notification::PERMITTED_ATTRIBUTES
        end

        def resource_scope
          current_account_list.notifications
        end
      end
    end
  end
end
