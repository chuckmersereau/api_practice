module Auth
  module Provider
    class DonorhubAccountsController < BaseController
      protected

      def find_or_create_account
        @donorhub_account ||=
          Person::OrganizationAccount.find_or_create_from_auth(
            auth_hash['credentials']['token'],
            params[:oauth_url],
            current_user
          )
      end
    end
  end
end
