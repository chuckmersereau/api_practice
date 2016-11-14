module Api
  module V2
    module AccountLists
      class ImportsController < AccountListsController
        def resource_attributes
          Import::PERMITTED_ATTRIBUTES
        end

        def resource_scope
          current_account_list.imports
        end
      end
    end
  end
end
