module Api
  module V2
    module AccountLists
      class MergeController < AccountListsController
        def create
          load_merge_account_list
          return render_400 unless @merge_account_list != current_account_list
          current_account_list.merge(@merge_account_list)
          render_200
        end

        private

        def load_merge_account_list
          @merge_account_list ||= resource_scope.find(resource_params[:id])
        end

        def resource_attributes
          [:id]
        end

        def resource_scope
          current_user.account_lists
        end
      end
    end
  end
end
