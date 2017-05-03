module Auth
  module Provider
    class MailChimpAccountsController < BaseController
      protected

      def find_or_create_account
        mail_chimp_account.attributes = { api_key: auth_hash.extra.api_token_with_dc }
        mail_chimp_account.save
      end

      def mail_chimp_account
        @mail_chimp_account ||= current_account_list.mail_chimp_account || current_account_list.build_mail_chimp_account
      end
    end
  end
end
