module Concerns
  module TntImport
    module DateHelpers
      private

      def parse_date(date_as_string, user)
        zone = user&.time_zone ? Time.find_zone(user.time_zone) || Time.zone : Time.zone
        zone.parse(date_as_string)
      end
    end
  end
end
