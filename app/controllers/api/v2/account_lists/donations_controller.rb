module Api
  module V2
    module AccountLists
      class DonationsController < AccountListsController
        def index
          load_resources
          render json: @resources, scope: { account_list: current_account_list, locale: locale }
        end

        def show
          load_resource
          render json: @resource, scope: { account_list: current_account_list, locale: locale }
        end

        def resource_attributes
          Donation::PERMITTED_ATTRIBUTES
        end

        def resource_scope
          current_account_list.donations
        end
      end
    end
  end
end
