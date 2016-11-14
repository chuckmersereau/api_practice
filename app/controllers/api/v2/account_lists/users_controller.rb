module Api
  module V2
    module AccountLists
      class UsersController < AccountListsController
        def pundit_user
          current_user
        end

        def destroy
          @resource.remove_access(current_account_list)
          render_200
        end

        def resource_scope
          current_account_list.users
        end
      end
    end
  end
end
