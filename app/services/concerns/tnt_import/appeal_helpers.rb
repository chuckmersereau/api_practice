module Concerns
  module TntImport
    module AppealHelpers
      private

      def appeal_table_name
        return 'Appeal' if @xml.version < 3.2
        'Campaign'
      end

      def appeal_id_name
        return 'AppealID' if @xml.version < 3.2
        'CampaignID'
      end

      def appeal_amount_name
        return 'AppealAmount' if @xml.version < 3.2
        'CampaignAmount'
      end
    end
  end
end
