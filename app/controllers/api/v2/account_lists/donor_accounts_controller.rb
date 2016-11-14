module Api
  module V2
    module AccountLists
      class DonorAccountsController < AccountListsController
        def resource_scope
          current_account_list.donor_accounts
        end
      end
    end
  end
end
