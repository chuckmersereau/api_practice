module Auth
  module Provider
    class GoogleAccountsController < BaseController
      protected

      def find_or_create_account
        @google_account ||= Person::GoogleAccount.find_or_create_from_auth(auth_hash, current_user)
      end
    end
  end
end
