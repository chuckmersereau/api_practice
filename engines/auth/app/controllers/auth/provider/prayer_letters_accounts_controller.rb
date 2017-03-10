module Auth
  module Provider
    class PrayerLettersAccountsController < BaseController
      protected

      def find_or_create_account
        prayer_letters_account.attributes = { oauth2_token: auth_hash.credentials.token, valid_token: true }
        prayer_letters_account.save
      end

      def prayer_letters_account
        @prayer_letters_account ||= current_account_list.prayer_letters_account || current_account_list.build_prayer_letters_account
      end
    end
  end
end
