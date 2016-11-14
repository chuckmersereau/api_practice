module Api
  module V2
    module AccountLists
      class FiltersController < AccountListsController
        def load_resources
          @resources = {}
          @resources[:contact_filters] = contact_filters if params[:contact] == '1'
          @resources[:task_filters] = task_filters if params[:task] == '1'
        end

        def resource_scope
          current_account_list
        end

        private

        def contact_filters
          Contact::Filterer.config(resource_scope)
        end

        def task_filters
          Task::Filterer.config(resource_scope)
        end
      end
    end
  end
end
